// carsim - simulated "rest of the car" for the emulated MGU22 iDrive.
//
// A vsomeip 3.5 application on the head unit's own SOME/IP bus that offers the services the HMI
// expects from other ECUs (climate, vehicle data, cluster...). Raw SOME/IP payloads, configured
// in a small text format so services can be discovered and filled in incrementally.
//
// Config / control lines (file given as argv[1], and live via the FIFO in argv[2]):
//   service  <svc> <inst> <major> <minor>          offer a service
//   event    <svc> <inst> <event> <eventgroup>     offer a field/event (notifier)
//   set      <svc> <inst> <event> <hex>            set a field value and notify subscribers
//   getter   <svc> <inst> <method> <event>         method returns the current value of <event>
//   setter   <svc> <inst> <method> <event>         method stores payload into <event>, notifies, echoes
//   reply    <svc> <inst> <method> <hex>           canned reply payload for a method
//   onreq    <svc> <inst> <method> <event> <hex>   on this request, set <event> to <hex> (e.g. button)
//   merge    <svc> <inst> <method> <event> <skip> <elemsize> <keyoff>
//            request array elements (after <skip> bytes) replace same-key elements of field <event>
//            (all three numbers hex; e.g. per-zone climate setpoints)
//   dump                                           print all field values
// Numbers are hex (with or without 0x). Payload "-" = empty.
// Every incoming request is logged: "REQ svc.inst method from client: payload".

#include <vsomeip/vsomeip.hpp>

#include <chrono>
#include <cstdio>
#include <fstream>
#include <iostream>
#include <map>
#include <mutex>
#include <set>
#include <sstream>
#include <string>
#include <thread>
#include <tuple>
#include <vector>
#include <fcntl.h>
#include <unistd.h>
#include <sys/stat.h>

using namespace vsomeip;
using bytes = std::vector<byte_t>;

static std::shared_ptr<application> app;
static std::mutex mtx;

using SI = std::pair<service_t, instance_t>;
struct Svc { major_version_t major = 1; minor_version_t minor = 0; bool offered = false; };
static std::map<SI, Svc> services;
static std::map<std::tuple<service_t, instance_t, event_t>, bytes> fields;
static std::map<std::tuple<service_t, instance_t, event_t>, std::set<eventgroup_t>> events;
static std::map<std::tuple<service_t, instance_t, method_t>, event_t> getters, setters;
static std::map<std::tuple<service_t, instance_t, method_t>, bytes> replies;
static std::map<std::tuple<service_t, instance_t, method_t>, std::pair<event_t, bytes>> onreq;
// merge: request = <skip bytes> u32 len, elements[elemsize]; status field = u32 len, elements.
// Each request element replaces the field element with the same key byte (offset keyoff).
struct Merge { event_t ev; unsigned skip, esize, keyoff; };
static void notify(service_t s, instance_t i, event_t e);
static std::map<std::tuple<service_t, instance_t, method_t>, Merge> merges;

static void do_merge(service_t s, instance_t i, const Merge &mg, const byte_t *p, size_t n)
{
    if (n < mg.skip + 4) return;
    p += mg.skip; n -= mg.skip;
    uint32_t len = (p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3];
    p += 4; n -= 4;
    if (len > n) len = (uint32_t)n;
    bytes &f = fields[{s, i, mg.ev}];
    if (f.size() < 4) f = {0, 0, 0, 0};
    std::vector<bytes> els;
    for (size_t o = 4; o + mg.esize <= f.size(); o += mg.esize) els.emplace_back(f.begin() + o, f.begin() + o + mg.esize);
    for (size_t o = 0; o + mg.esize <= len; o += mg.esize) {
        bytes e(p + o, p + o + mg.esize);
        bool done = false;
        for (auto &x : els) if (x[mg.keyoff] == e[mg.keyoff]) { x = e; done = true; }
        if (!done) els.push_back(e);
    }
    uint32_t total = (uint32_t)(els.size() * mg.esize);
    bytes out = {(byte_t)(total >> 24), (byte_t)(total >> 16), (byte_t)(total >> 8), (byte_t)total};
    for (auto &x : els) out.insert(out.end(), x.begin(), x.end());
    f = out;
    notify(s, i, mg.ev);
}

static unsigned long hexnum(const std::string &s) {
    unsigned long v = 0;
    size_t i = (s.size() > 2 && s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) ? 2 : 0;
    for (; i < s.size(); i++) {
        char c = s[i];
        int d = (c >= '0' && c <= '9') ? c - '0' : (c >= 'a' && c <= 'f') ? c - 'a' + 10
              : (c >= 'A' && c <= 'F') ? c - 'A' + 10 : -1;
        if (d < 0) break;
        v = v * 16 + d;
    }
    return v;
}

static bytes hexbytes(const std::string &s) {
    bytes b;
    if (s == "-") return b;
    std::string h;
    for (char c : s) if (isxdigit((unsigned char)c)) h += c;
    for (size_t i = 0; i + 1 < h.size(); i += 2) b.push_back((byte_t)hexnum(h.substr(i, 2)));
    return b;
}

static std::string tohex(const byte_t *p, size_t n) {
    static const char *d = "0123456789abcdef";
    std::string s;
    for (size_t i = 0; i < n; i++) { s += d[p[i] >> 4]; s += d[p[i] & 15]; if (i + 1 < n) s += ' '; }
    return s.empty() ? "-" : s;
}

static void log(const std::string &m) {
    std::cout << m << std::endl;
}

static void notify(service_t s, instance_t i, event_t e) {
    auto it = fields.find({s, i, e});
    if (it == fields.end()) return;
    auto pl = runtime::get()->create_payload(it->second);
    app->notify(s, i, e, pl, true);
}

static void offer(const SI &si) {
    auto &sv = services[si];
    for (auto &ev : events)
        if (std::get<0>(ev.first) == si.first && std::get<1>(ev.first) == si.second)
            app->offer_event(si.first, si.second, std::get<2>(ev.first), ev.second,
                             event_type_e::ET_FIELD, std::chrono::milliseconds::zero(), false, true);
    if (!sv.offered) {
        app->offer_service(si.first, si.second, sv.major, sv.minor);
        sv.offered = true;
    }
    for (auto &f : fields)
        if (std::get<0>(f.first) == si.first && std::get<1>(f.first) == si.second)
            notify(si.first, si.second, std::get<2>(f.first));
}

static void on_message(const std::shared_ptr<message> &req) {
    std::lock_guard<std::mutex> lk(mtx);
    auto s = req->get_service(), i = req->get_instance();
    auto m = req->get_method();
    auto pl = req->get_payload();
    char head[96];
    snprintf(head, sizeof head, "REQ %04x.%04x m=%04x from %04x type=%d: ", s, i, m, req->get_client(),
             (int)req->get_message_type());
    log(head + tohex(pl->get_data(), pl->get_length()));

    bytes out;
    auto key = std::make_tuple(s, i, m);
    if (onreq.count(key)) {
        auto &o = onreq[key];
        fields[{s, i, o.first}] = o.second;
        notify(s, i, o.first);
    }
    if (merges.count(key))
        do_merge(s, i, merges[key], pl->get_data(), pl->get_length());
    if (setters.count(key)) {
        event_t e = setters[key];
        fields[{s, i, e}] = bytes(pl->get_data(), pl->get_data() + pl->get_length());
        notify(s, i, e);
        out = fields[{s, i, e}];
    } else if (getters.count(key)) {
        out = fields[{s, i, getters[key]}];
    } else if (replies.count(key)) {
        out = replies[key];
    }
    if (req->get_message_type() == message_type_e::MT_REQUEST) {
        auto resp = runtime::get()->create_response(req);
        resp->set_payload(runtime::get()->create_payload(out));
        app->send(resp);
    }
}

static void command(const std::string &line) {
    std::istringstream ss(line);
    std::string op, a, b, c, d, e;
    ss >> op >> a >> b >> c >> d >> e;
    if (op.empty() || op[0] == '#') return;
    std::lock_guard<std::mutex> lk(mtx);
    service_t s = (service_t)hexnum(a); instance_t i = (instance_t)hexnum(b);
    if (op == "service") {
        auto &sv = services[{s, i}];
        sv.major = (major_version_t)hexnum(c); sv.minor = (minor_version_t)hexnum(d);
        app->register_message_handler(s, i, ANY_METHOD, on_message);
        if (app->is_routing() || true) offer({s, i});
    } else if (op == "event") {
        events[{s, i, (event_t)hexnum(c)}].insert((eventgroup_t)hexnum(d));
        if (services[{s, i}].offered)
            app->offer_event(s, i, (event_t)hexnum(c), events[{s, i, (event_t)hexnum(c)}],
                             event_type_e::ET_FIELD, std::chrono::milliseconds::zero(), false, true);
    } else if (op == "set") {
        // payload may be split over several words: everything after the event id
        std::string rest, w;
        while (ss >> w) rest += w;
        fields[{s, i, (event_t)hexnum(c)}] = hexbytes(d + e + rest);
        notify(s, i, (event_t)hexnum(c));
    } else if (op == "getter") {
        getters[{s, i, (method_t)hexnum(c)}] = (event_t)hexnum(d);
    } else if (op == "setter") {
        setters[{s, i, (method_t)hexnum(c)}] = (event_t)hexnum(d);
    } else if (op == "reply") {
        replies[{s, i, (method_t)hexnum(c)}] = hexbytes(d + e);
    } else if (op == "merge") {  // merge <svc> <inst> <method> <event> <skip> <elemsize> <keyoff>
        std::string f, g;
        ss >> f >> g;
        merges[{s, i, (method_t)hexnum(c)}] = {(event_t)hexnum(d), (unsigned)hexnum(e), (unsigned)hexnum(f),
                                              (unsigned)hexnum(g)};
    } else if (op == "onreq") {
        onreq[{s, i, (method_t)hexnum(c)}] = {(event_t)hexnum(d), hexbytes(e)};
    } else if (op == "dump") {
        for (auto &f : fields) {
            char h[64];
            snprintf(h, sizeof h, "FIELD %04x.%04x.%04x = ", std::get<0>(f.first), std::get<1>(f.first),
                     std::get<2>(f.first));
            log(h + tohex(f.second.data(), f.second.size()));
        }
        return;
    } else {
        log("unknown command: " + line);
        return;
    }
    log("ok: " + line);
}

static void fifo_loop(std::string path) {
    unlink(path.c_str());
    mkfifo(path.c_str(), 0666);
    for (;;) {
        std::ifstream f(path);  // blocks until a writer opens it
        std::string ln;
        while (std::getline(f, ln)) {
            if (!ln.empty() && ln.back() == '\r') ln.pop_back();
            command(ln);
        }
    }
}

int main(int argc, char **argv) {
    std::string cfg = argc > 1 ? argv[1] : "/opt/emu/carsim.conf";
    std::string fifo = argc > 2 ? argv[2] : "/tmp/carsim.fifo";
    app = runtime::get()->create_application("carsim");
    if (!app->init()) { std::cerr << "vsomeip init failed" << std::endl; return 1; }
    std::thread([cfg] {
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        std::ifstream f(cfg);
        std::string ln;
        int n = 0;
        while (std::getline(f, ln)) { if (!ln.empty() && ln.back() == '\r') ln.pop_back(); command(ln); n++; }
        log("config loaded: " + std::to_string(n) + " lines from " + cfg);
    }).detach();
    std::thread(fifo_loop, fifo).detach();
    app->start();
    return 0;
}
