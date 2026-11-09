/* tone: play a short sine chord through an ALSA PCM (default "HarmanX:test") to verify the
 * emulator's audio path. Built for aarch64 against the firmware's libasound (no headers needed). */
#include <math.h>
#include <stdio.h>
#include <stdint.h>

typedef struct snd_pcm snd_pcm_t;
int snd_pcm_open(snd_pcm_t **pcm, const char *name, int stream, int mode);
int snd_pcm_set_params(snd_pcm_t *pcm, int format, int access, unsigned channels, unsigned rate,
                       int soft_resample, unsigned latency_us);
long snd_pcm_writei(snd_pcm_t *pcm, const void *buf, unsigned long frames);
int snd_pcm_drain(snd_pcm_t *pcm);
int snd_pcm_close(snd_pcm_t *pcm);
const char *snd_strerror(int err);
#define SND_PCM_STREAM_PLAYBACK 0
#define SND_PCM_FORMAT_S16_LE 2
#define SND_PCM_ACCESS_RW_INTERLEAVED 3

int main(int argc, char **argv)
{
    const char *dev = argc > 1 ? argv[1] : "HarmanX:test";
    snd_pcm_t *pcm;
    int e = snd_pcm_open(&pcm, dev, SND_PCM_STREAM_PLAYBACK, 0);
    if (e < 0) { printf("open %s: %s\n", dev, snd_strerror(e)); return 1; }
    e = snd_pcm_set_params(pcm, SND_PCM_FORMAT_S16_LE, SND_PCM_ACCESS_RW_INTERLEAVED, 2, 48000, 1, 200000);
    if (e < 0) { printf("params: %s\n", snd_strerror(e)); return 1; }
    static int16_t buf[48000 * 2];
    const double f[3] = {440.0, 554.37, 659.25};   /* A major chord, ~1.5 s */
    for (int n = 0; n < 3; n++) {
        for (int i = 0; i < 24000; i++) {
            double s = sin(2 * M_PI * f[n] * i / 48000.0) * 0.25 * (1.0 - i / 24000.0);
            buf[2 * i] = buf[2 * i + 1] = (int16_t)(s * 32767);
        }
        long w = snd_pcm_writei(pcm, buf, 24000);
        if (w < 0) { printf("write: %s\n", snd_strerror((int)w)); return 1; }
    }
    snd_pcm_drain(pcm);
    snd_pcm_close(pcm);
    printf("played to %s\n", dev);
    return 0;
}
