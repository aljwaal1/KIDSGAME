package com.explapp.kidsgame.legacy;

import android.content.Context;
import android.content.SharedPreferences;
import android.media.AudioManager;
import android.media.ToneGenerator;

/** Lightweight, offline sound engine tuned for old Android devices. */
final class InteractionSound {
    static final int CLICK = 1;
    static final int NAVIGATE = 2;
    static final int MOVE_X = 3;
    static final int MOVE_O = 4;
    static final int CORRECT = 5;
    static final int WRONG = 6;
    static final int WIN = 7;
    static final int DRAW = 8;
    static final int RESTART = 9;

    private final SharedPreferences preferences;
    private ToneGenerator tones;
    private boolean enabled;
    private long lastPlayedAt;

    InteractionSound(Context context) {
        preferences = context.getSharedPreferences("legacy_sound", Context.MODE_PRIVATE);
        enabled = preferences.getBoolean("enabled", true);
        tones = new ToneGenerator(AudioManager.STREAM_MUSIC, 82);
    }

    boolean isEnabled() { return enabled; }

    boolean toggle() {
        enabled = !enabled;
        preferences.edit().putBoolean("enabled", enabled).apply();
        if (enabled) play(CORRECT);
        return enabled;
    }

    void play(int event) {
        if (!enabled || tones == null) return;
        long now = System.currentTimeMillis();
        if (now - lastPlayedAt < 45L && event != WIN) return;
        lastPlayedAt = now;

        switch (event) {
            case NAVIGATE:
                tones.startTone(ToneGenerator.TONE_PROP_BEEP2, 75);
                break;
            case MOVE_X:
                tones.startTone(ToneGenerator.TONE_DTMF_1, 85);
                break;
            case MOVE_O:
                tones.startTone(ToneGenerator.TONE_DTMF_6, 85);
                break;
            case CORRECT:
                tones.startTone(ToneGenerator.TONE_PROP_ACK, 130);
                break;
            case WRONG:
                tones.startTone(ToneGenerator.TONE_PROP_NACK, 140);
                break;
            case WIN:
                tones.startTone(ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, 430);
                break;
            case DRAW:
                tones.startTone(ToneGenerator.TONE_CDMA_ABBR_INTERCEPT, 220);
                break;
            case RESTART:
                tones.startTone(ToneGenerator.TONE_DTMF_0, 110);
                break;
            default:
                tones.startTone(ToneGenerator.TONE_PROP_BEEP, 65);
                break;
        }
    }

    void release() {
        if (tones != null) {
            tones.release();
            tones = null;
        }
    }
}
