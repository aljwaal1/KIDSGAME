package com.explapp.kidsgamelegacy;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.media.AudioManager;
import android.media.ToneGenerator;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.view.Gravity;
import android.view.MotionEvent;
import android.view.View;
import android.view.Window;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Random;

/**
 * Native, lightweight Kids Games Arena for Android 4.4.
 * Keeps the original three games: letter bubbles, tic-tac-toe and sliding puzzle.
 */
public final class MainActivity extends Activity {
    private static final String PREFS = "kids_arena_legacy_v3";
    private static final int PURPLE = 0xff5b3fc4;
    private static final int DARK = 0xff241a52;
    private static final int BG = 0xfff7f5ff;
    private static final int MUTED = 0xff6b7280;
    private static final int TEAL = 0xff079a91;
    private static final int ORANGE = 0xffef7d32;
    private static final int PINK = 0xffd94d87;

    private final Random random = new Random();
    private final Handler handler = new Handler();
    private SharedPreferences prefs;
    private ToneGenerator tones;
    private boolean soundOn = true;
    private boolean home = true;
    private int stars;
    private int rounds;
    private int best;
    private int streak;

    private final String[] xo = new String[9];
    private String xoTurn = "X";
    private boolean xoFinished;
    private int[] xoWinLine;

    private final int[] puzzle = new int[9];
    private int puzzleMoves;

    private BubbleView bubbleView;

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setBackgroundDrawableResource(android.R.color.white);
        prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
        stars = prefs.getInt("stars", 0);
        rounds = prefs.getInt("rounds", 0);
        best = prefs.getInt("best", 0);
        soundOn = prefs.getBoolean("sound", true);
        tones = new ToneGenerator(AudioManager.STREAM_MUSIC, 28);
        showHome();
    }

    @Override protected void onDestroy() {
        handler.removeCallbacksAndMessages(null);
        if (tones != null) tones.release();
        super.onDestroy();
    }

    private void showHome() {
        stopBubbleGame();
        home = true;
        LinearLayout root = page();
        root.addView(new HeroView(this), new LinearLayout.LayoutParams(-1, dp(154)));

        TextView title = label("ملعب الأطفال", 29, DARK, true);
        title.setGravity(Gravity.CENTER);
        root.addView(title, top(7));

        TextView subtitle = label("ثلاث ألعاب ممتعة للتفكير والتعلّم", 15, MUTED, false);
        subtitle.setGravity(Gravity.CENTER);
        root.addView(subtitle, top(2));

        LinearLayout stats = row();
        stats.addView(stat("النجوم", stars, 0xffffc83d), weight());
        stats.addView(space(7));
        stats.addView(stat("الجولات", rounds, 0xff6ed7cf), weight());
        stats.addView(space(7));
        stats.addView(stat("أفضل سلسلة", best, 0xffff8eb9), weight());
        root.addView(stats, top(12));

        root.addView(sectionTitle("اختر لعبتك"), top(15));
        root.addView(gameCard("فقاعات الحروف", "المس الحرف المطلوب قبل أن يبتعد", PINK, "أ ب",
                new View.OnClickListener() { @Override public void onClick(View v) { startBubbles(); } }), top(8));
        root.addView(gameCard("إكس أو", "لعبة لاعبين مع إظهار خط الفوز", PURPLE, "X O",
                new View.OnClickListener() { @Override public void onClick(View v) { startXo(); } }), top(9));
        root.addView(gameCard("البزل المنزلق", "رتّب الأرقام من 1 إلى 8 بأقل حركات", TEAL, "1 2",
                new View.OnClickListener() { @Override public void onClick(View v) { startPuzzle(); } }), top(9));

        LinearLayout controls = row();
        TextView sound = action(soundOn ? "الصوت: يعمل" : "الصوت: متوقف", soundOn ? TEAL : MUTED);
        sound.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                soundOn = !soundOn;
                prefs.edit().putBoolean("sound", soundOn).apply();
                if (soundOn) playTap();
                showHome();
            }
        });
        TextView reset = action("إعادة التقدم", MUTED);
        reset.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { confirmReset(); }
        });
        controls.addView(sound, weight());
        controls.addView(space(8));
        controls.addView(reset, weight());
        root.addView(controls, top(13));

        setPage(root, true);
    }

    private void startBubbles() {
        home = false;
        stopBubbleGame();
        LinearLayout root = gameShell("فقاعات الحروف", "المس الفقاعة التي تحمل الحرف المطلوب", PINK);
        bubbleView = new BubbleView(this);
        root.addView(bubbleView, new LinearLayout.LayoutParams(-1, dp(365)));
        setPage(root, false);
        bubbleView.startRound();
    }

    private void startXo() {
        stopBubbleGame();
        Arrays.fill(xo, "");
        xoTurn = "X";
        xoFinished = false;
        xoWinLine = null;
        showXo();
    }

    private void showXo() {
        home = false;
        LinearLayout root = gameShell("إكس أو", xoFinished ? "انتهت الجولة" : "دور اللاعب " + xoTurn, PURPLE);
        XoBoard board = new XoBoard(this);
        root.addView(board, new LinearLayout.LayoutParams(-1, dp(315)));
        TextView newRound = primary("جولة جديدة", PURPLE);
        newRound.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { playTap(); startXo(); }
        });
        root.addView(newRound, top(10));
        setPage(root, false);
    }

    private void xoMove(int index) {
        if (xoFinished || xo[index].length() != 0) return;
        xo[index] = xoTurn;
        playTap();
        xoWinLine = findWin(xoTurn);
        if (xoWinLine != null) {
            xoFinished = true;
            win(5, "فاز اللاعب " + xoTurn);
            showXo();
            return;
        }
        boolean full = true;
        for (String cell : xo) if (cell.length() == 0) full = false;
        if (full) {
            xoFinished = true;
            rounds++;
            save();
            playSuccess();
            toast("تعادل رائع");
            showXo();
            return;
        }
        xoTurn = xoTurn.equals("X") ? "O" : "X";
        showXo();
    }

    private int[] findWin(String mark) {
        int[][] lines = {{0,1,2},{3,4,5},{6,7,8},{0,3,6},{1,4,7},{2,5,8},{0,4,8},{2,4,6}};
        for (int[] line : lines) {
            if (xo[line[0]].equals(mark) && xo[line[1]].equals(mark) && xo[line[2]].equals(mark)) return line;
        }
        return null;
    }

    private void startPuzzle() {
        stopBubbleGame();
        for (int i = 0; i < 9; i++) puzzle[i] = (i + 1) % 9;
        int blank = 8;
        int previous = -1;
        for (int n = 0; n < 160; n++) {
            ArrayList<Integer> legal = legalPuzzleMoves(blank);
            legal.remove((Integer) previous);
            if (legal.isEmpty()) legal = legalPuzzleMoves(blank);
            int next = legal.get(random.nextInt(legal.size()));
            puzzle[blank] = puzzle[next];
            puzzle[next] = 0;
            previous = blank;
            blank = next;
        }
        if (puzzleSolved()) {
            puzzle[7] = 0;
            puzzle[8] = 8;
        }
        puzzleMoves = 0;
        showPuzzle();
    }

    private void showPuzzle() {
        home = false;
        LinearLayout root = gameShell("البزل المنزلق", "الحركات: " + puzzleMoves + "  •  اضغط رقمًا بجانب الفراغ", TEAL);
        PuzzleBoard board = new PuzzleBoard(this);
        root.addView(board, new LinearLayout.LayoutParams(-1, dp(320)));
        TextView shuffle = primary("خلط جديد", TEAL);
        shuffle.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { playTap(); startPuzzle(); }
        });
        root.addView(shuffle, top(9));
        setPage(root, false);
    }

    private ArrayList<Integer> legalPuzzleMoves(int blank) {
        ArrayList<Integer> moves = new ArrayList<Integer>();
        int row = blank / 3, col = blank % 3;
        if (row > 0) moves.add(blank - 3);
        if (row < 2) moves.add(blank + 3);
        if (col > 0) moves.add(blank - 1);
        if (col < 2) moves.add(blank + 1);
        return moves;
    }

    private void puzzleTap(int index) {
        int blank = 0;
        while (blank < 9 && puzzle[blank] != 0) blank++;
        if (!legalPuzzleMoves(blank).contains(index)) {
            playWrong();
            return;
        }
        puzzle[blank] = puzzle[index];
        puzzle[index] = 0;
        puzzleMoves++;
        playTap();
        if (puzzleSolved()) {
            int reward = Math.max(4, 15 - puzzleMoves / 15);
            win(reward, "أكملت البزل في " + puzzleMoves + " حركة");
            startPuzzle();
        } else {
            showPuzzle();
        }
    }

    private boolean puzzleSolved() {
        for (int i = 0; i < 8; i++) if (puzzle[i] != i + 1) return false;
        return puzzle[8] == 0;
    }

    private LinearLayout gameShell(String title, String subtitle, int color) {
        LinearLayout root = page();
        LinearLayout nav = row();
        TextView back = action("العودة", MUTED);
        back.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) { playTap(); showHome(); }
        });
        TextView sound = action(soundOn ? "الصوت يعمل" : "الصوت متوقف", soundOn ? TEAL : MUTED);
        sound.setOnClickListener(new View.OnClickListener() {
            @Override public void onClick(View v) {
                soundOn = !soundOn;
                prefs.edit().putBoolean("sound", soundOn).apply();
                if (soundOn) playTap();
                if (bubbleView != null) startBubbles(); else if (title.indexOf("إكس") >= 0) showXo(); else showPuzzle();
            }
        });
        nav.addView(back, weight());
        nav.addView(space(8));
        nav.addView(sound, weight());
        root.addView(nav);

        TextView header = label(title + "\n" + subtitle, 21, Color.WHITE, true);
        header.setGravity(Gravity.CENTER);
        header.setPadding(dp(10), dp(16), dp(10), dp(16));
        header.setBackground(round(color, 20));
        root.addView(header, top(9));

        TextView score = label("النجوم " + stars + "   •   السلسلة " + streak, 14, DARK, true);
        score.setGravity(Gravity.CENTER);
        score.setPadding(dp(5), dp(9), dp(5), dp(9));
        score.setBackground(round(0xffffffff, 30));
        root.addView(score, top(8));
        return root;
    }

    private void stopBubbleGame() {
        if (bubbleView != null) {
            bubbleView.stop();
            bubbleView = null;
        }
        handler.removeCallbacksAndMessages(null);
    }

    private void win(int reward, String message) {
        stars += reward;
        rounds++;
        streak++;
        if (streak > best) best = streak;
        save();
        playSuccess();
        toast(message + "  +" + reward + " نجوم");
    }

    private void miss() {
        streak = 0;
        save();
        playWrong();
        toast("حاول مرة أخرى");
    }

    private void save() {
        prefs.edit().putInt("stars", stars).putInt("rounds", rounds).putInt("best", best).apply();
    }

    private void confirmReset() {
        new AlertDialog.Builder(this)
                .setTitle("إعادة ضبط التقدم")
                .setMessage("هل تريد حذف النجوم والجولات وأفضل سلسلة؟")
                .setPositiveButton("إعادة الضبط", new DialogInterface.OnClickListener() {
                    @Override public void onClick(DialogInterface dialog, int which) {
                        stars = rounds = best = streak = 0;
                        save();
                        showHome();
                    }
                })
                .setNegativeButton("إلغاء", null)
                .show();
    }

    private void playTap() {
        if (soundOn && tones != null) tones.startTone(ToneGenerator.TONE_PROP_BEEP, 55);
    }

    private void playSuccess() {
        if (soundOn && tones != null) tones.startTone(ToneGenerator.TONE_PROP_ACK, 130);
    }

    private void playWrong() {
        if (soundOn && tones != null) tones.startTone(ToneGenerator.TONE_PROP_NACK, 90);
    }

    private LinearLayout page() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(12), dp(12), dp(12), dp(20));
        if (Build.VERSION.SDK_INT >= 17) root.setLayoutDirection(View.LAYOUT_DIRECTION_RTL);
        return root;
    }

    private void setPage(LinearLayout root, boolean scrollable) {
        root.setAlpha(0f);
        if (scrollable) {
            ScrollView scroll = new ScrollView(this);
            scroll.setFillViewport(true);
            scroll.setBackgroundColor(BG);
            scroll.addView(root);
            setContentView(scroll);
        } else {
            root.setBackgroundColor(BG);
            setContentView(root);
        }
        root.animate().alpha(1f).setDuration(190).start();
    }

    private LinearLayout gameCard(String title, String subtitle, int color, String symbol, View.OnClickListener listener) {
        LinearLayout card = row();
        card.setGravity(Gravity.CENTER_VERTICAL);
        card.setPadding(dp(11), dp(10), dp(11), dp(10));
        card.setBackground(cardBackground(0xffffffff, 18, 0xffe4defb));
        card.setOnClickListener(listener);

        BadgeView badge = new BadgeView(this, color, symbol);
        card.addView(badge, new LinearLayout.LayoutParams(dp(62), dp(62)));

        LinearLayout copy = new LinearLayout(this);
        copy.setOrientation(LinearLayout.VERTICAL);
        copy.setPadding(dp(12), 0, dp(7), 0);
        TextView t = label(title, 19, DARK, true);
        TextView s = label(subtitle, 13, MUTED, false);
        copy.addView(t);
        copy.addView(s, top(3));
        card.addView(copy, new LinearLayout.LayoutParams(0, -2, 1f));

        TextView arrow = label("‹", 34, color, true);
        arrow.setGravity(Gravity.CENTER);
        card.addView(arrow, new LinearLayout.LayoutParams(dp(30), -1));
        return card;
    }

    private TextView stat(String name, int value, int accent) {
        TextView v = label(name + "\n" + value, 13, DARK, true);
        v.setGravity(Gravity.CENTER);
        v.setPadding(dp(3), dp(9), dp(3), dp(9));
        GradientDrawable d = cardBackground(0xffffffff, 16, accent);
        d.setStroke(dp(2), accent);
        v.setBackground(d);
        return v;
    }

    private TextView sectionTitle(String text) {
        TextView v = label(text, 18, DARK, true);
        v.setGravity(Gravity.RIGHT);
        return v;
    }

    private TextView primary(String text, int color) {
        TextView v = label(text, 16, Color.WHITE, true);
        v.setGravity(Gravity.CENTER);
        v.setPadding(dp(8), dp(14), dp(8), dp(14));
        v.setBackground(round(color, 16));
        return v;
    }

    private TextView action(String text, int color) {
        TextView v = label(text, 14, color, true);
        v.setGravity(Gravity.CENTER);
        v.setPadding(dp(7), dp(11), dp(7), dp(11));
        v.setBackground(cardBackground(0xffffffff, 14, 0xffded8f4));
        return v;
    }

    private TextView label(String text, int size, int color, boolean bold) {
        TextView v = new TextView(this);
        v.setText(text);
        v.setTextSize(size);
        v.setTextColor(color);
        v.setTypeface(Typeface.DEFAULT, bold ? Typeface.BOLD : Typeface.NORMAL);
        return v;
    }

    private LinearLayout row() {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        return row;
    }

    private GradientDrawable round(int color, int radius) {
        GradientDrawable d = new GradientDrawable();
        d.setColor(color);
        d.setCornerRadius(dp(radius));
        return d;
    }

    private GradientDrawable cardBackground(int color, int radius, int stroke) {
        GradientDrawable d = round(color, radius);
        d.setStroke(dp(1), stroke);
        return d;
    }

    private View space(int width) {
        View v = new View(this);
        v.setLayoutParams(new LinearLayout.LayoutParams(dp(width), 1));
        return v;
    }

    private LinearLayout.LayoutParams weight() { return new LinearLayout.LayoutParams(0, -2, 1f); }
    private LinearLayout.LayoutParams top(int margin) {
        LinearLayout.LayoutParams p = new LinearLayout.LayoutParams(-1, -2);
        p.topMargin = dp(margin);
        return p;
    }
    private int dp(int value) { return (int) (value * getResources().getDisplayMetrics().density + .5f); }
    private void toast(String text) { Toast.makeText(this, text, Toast.LENGTH_SHORT).show(); }

    @Override public void onBackPressed() {
        if (home) super.onBackPressed(); else showHome();
    }

    private final class HeroView extends View {
        private final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final Path star = new Path();
        HeroView(Activity context) { super(context); setContentDescription("ملعب أطفال ملوّن"); }

        @Override protected void onDraw(Canvas c) {
            float w = getWidth(), h = getHeight();
            p.setShader(new android.graphics.LinearGradient(0, 0, w, h, PURPLE, 0xff8a5ce6,
                    android.graphics.Shader.TileMode.CLAMP));
            c.drawRoundRect(new RectF(0, 0, w, h), dp(24), dp(24), p);
            p.setShader(null);
            p.setColor(0x3346e6dc);
            c.drawCircle(w * .12f, h * .25f, h * .28f, p);
            p.setColor(0x44ff8eb9);
            c.drawCircle(w * .89f, h * .78f, h * .35f, p);

            float x = w * .5f, y = h * .5f, r = h * .34f;
            star.reset();
            for (int i = 0; i < 10; i++) {
                double a = -Math.PI / 2 + i * Math.PI / 5;
                float rr = i % 2 == 0 ? r : r * .46f;
                float px = x + (float) Math.cos(a) * rr;
                float py = y + (float) Math.sin(a) * rr;
                if (i == 0) star.moveTo(px, py); else star.lineTo(px, py);
            }
            star.close();
            p.setColor(0xffffd44f);
            c.drawPath(star, p);
            p.setColor(DARK);
            c.drawCircle(x - r * .25f, y - r * .05f, r * .065f, p);
            c.drawCircle(x + r * .25f, y - r * .05f, r * .065f, p);
            p.setStyle(Paint.Style.STROKE);
            p.setStrokeWidth(dp(4));
            c.drawArc(new RectF(x-r*.30f, y, x+r*.30f, y+r*.35f), 12, 156, false, p);
            p.setStyle(Paint.Style.FILL);
        }
    }

    private final class BadgeView extends View {
        private final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final int color;
        private final String text;
        BadgeView(Activity context, int color, String text) { super(context); this.color = color; this.text = text; }

        @Override protected void onDraw(Canvas c) {
            p.setColor(color);
            c.drawRoundRect(new RectF(0, 0, getWidth(), getHeight()), dp(18), dp(18), p);
            p.setColor(Color.WHITE);
            p.setTextAlign(Paint.Align.CENTER);
            p.setTypeface(Typeface.DEFAULT_BOLD);
            p.setTextSize(dp(text.length() > 2 ? 17 : 22));
            Paint.FontMetrics fm = p.getFontMetrics();
            c.drawText(text, getWidth()/2f, getHeight()/2f-(fm.ascent+fm.descent)/2f, p);
        }
    }

    private final class XoBoard extends View {
        private final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        XoBoard(Activity context) { super(context); setContentDescription("لوحة إكس أو"); }

        @Override protected void onDraw(Canvas c) {
            float size = Math.min(getWidth(), getHeight()) - dp(18);
            float left = (getWidth() - size) / 2f, top = dp(9), cell = size / 3f;
            p.setColor(Color.WHITE);
            c.drawRoundRect(new RectF(left, top, left+size, top+size), dp(22), dp(22), p);
            p.setColor(0xffdcd5f5);
            p.setStrokeWidth(dp(3));
            for (int i = 1; i < 3; i++) {
                c.drawLine(left+i*cell, top+dp(12), left+i*cell, top+size-dp(12), p);
                c.drawLine(left+dp(12), top+i*cell, left+size-dp(12), top+i*cell, p);
            }
            p.setTextAlign(Paint.Align.CENTER);
            p.setTypeface(Typeface.DEFAULT_BOLD);
            p.setTextSize(cell * .54f);
            for (int i = 0; i < 9; i++) {
                if (xo[i].length() == 0) continue;
                p.setColor(xo[i].equals("X") ? PURPLE : ORANGE);
                Paint.FontMetrics fm = p.getFontMetrics();
                float cx = left + (i%3+.5f)*cell;
                float cy = top + (i/3+.5f)*cell - (fm.ascent+fm.descent)/2f;
                c.drawText(xo[i], cx, cy, p);
            }
            if (xoWinLine != null) {
                int a = xoWinLine[0], b = xoWinLine[2];
                p.setColor(0xffffc33d);
                p.setStrokeWidth(dp(9));
                p.setStrokeCap(Paint.Cap.ROUND);
                c.drawLine(left+(a%3+.5f)*cell, top+(a/3+.5f)*cell,
                        left+(b%3+.5f)*cell, top+(b/3+.5f)*cell, p);
            }
        }

        @Override public boolean onTouchEvent(MotionEvent event) {
            if (event.getAction() != MotionEvent.ACTION_UP || xoFinished) return true;
            float size = Math.min(getWidth(), getHeight()) - dp(18);
            float left = (getWidth()-size)/2f, top = dp(9);
            if (event.getX() < left || event.getX() > left+size || event.getY() < top || event.getY() > top+size) return true;
            int col = Math.min(2, (int)((event.getX()-left)/(size/3f)));
            int row = Math.min(2, (int)((event.getY()-top)/(size/3f)));
            xoMove(row*3+col);
            return true;
        }
    }

    private final class PuzzleBoard extends View {
        private final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        PuzzleBoard(Activity context) { super(context); setContentDescription("لوحة البزل المنزلق"); }

        @Override protected void onDraw(Canvas c) {
            float size = Math.min(getWidth(), getHeight()) - dp(14);
            float left = (getWidth()-size)/2f, top = dp(7), cell = size/3f;
            p.setColor(0xffe8e4f8);
            c.drawRoundRect(new RectF(left, top, left+size, top+size), dp(22), dp(22), p);
            for (int i=0;i<9;i++) {
                if (puzzle[i] == 0) continue;
                float pad = dp(5);
                float x = left+(i%3)*cell+pad, y = top+(i/3)*cell+pad;
                p.setColor((i+puzzle[i])%2==0 ? TEAL : 0xff36b8ae);
                c.drawRoundRect(new RectF(x,y,x+cell-pad*2,y+cell-pad*2),dp(17),dp(17),p);
                p.setColor(Color.WHITE);
                p.setTextAlign(Paint.Align.CENTER);
                p.setTypeface(Typeface.DEFAULT_BOLD);
                p.setTextSize(cell*.38f);
                Paint.FontMetrics fm=p.getFontMetrics();
                c.drawText(String.valueOf(puzzle[i]),x+(cell-pad*2)/2f,y+(cell-pad*2)/2f-(fm.ascent+fm.descent)/2f,p);
            }
        }

        @Override public boolean onTouchEvent(MotionEvent event) {
            if(event.getAction()!=MotionEvent.ACTION_UP)return true;
            float size=Math.min(getWidth(),getHeight())-dp(14);
            float left=(getWidth()-size)/2f,top=dp(7);
            if(event.getX()<left||event.getX()>left+size||event.getY()<top||event.getY()>top+size)return true;
            int col=Math.min(2,(int)((event.getX()-left)/(size/3f)));
            int row=Math.min(2,(int)((event.getY()-top)/(size/3f)));
            puzzleTap(row*3+col);
            return true;
        }
    }

    private final class BubbleView extends View implements Runnable {
        private final Paint p = new Paint(Paint.ANTI_ALIAS_FLAG);
        private final String[] letters = {"أ","ب","ت","ث","ج","ح","د","ر","س","ش","ع","ف","ق","ك","ل","م","ن","ه","و","ي"};
        private final int[] colors = {PINK, PURPLE, TEAL, ORANGE, 0xff2b87d1, 0xff8e63d9};
        private final ArrayList<Bubble> bubbles = new ArrayList<Bubble>();
        private String target;
        private boolean running;

        BubbleView(Activity context) { super(context); setContentDescription("لعبة فقاعات الحروف"); }

        void startRound() {
            bubbles.clear();
            target = letters[random.nextInt(letters.length)];
            for (int i=0;i<5;i++) addBubble(i);
            bubbles.get(random.nextInt(bubbles.size())).letter = target;
            running = true;
            postDelayed(this, 35);
            invalidate();
        }

        void stop() { running=false; removeCallbacks(this); }

        private void addBubble(int index) {
            Bubble b=new Bubble();
            b.r=dp(27+random.nextInt(9));
            b.x=dp(38)+random.nextFloat()*Math.max(dp(20),getResources().getDisplayMetrics().widthPixels-dp(100));
            b.y=dp(105)+index*dp(54);
            b.speed=dp(1)+random.nextFloat()*dp(1);
            b.letter=letters[random.nextInt(letters.length)];
            b.color=colors[random.nextInt(colors.length)];
            bubbles.add(b);
        }

        @Override public void run() {
            if(!running)return;
            for(Bubble b:bubbles){
                b.y-=b.speed;
                if(b.y<-b.r){
                    b.y=getHeight()+b.r;
                    b.x=b.r+random.nextFloat()*Math.max(1,getWidth()-2*b.r);
                    b.letter=letters[random.nextInt(letters.length)];
                }
            }
            boolean targetVisible=false;
            for(Bubble b:bubbles)if(b.letter.equals(target))targetVisible=true;
            if(!targetVisible)bubbles.get(random.nextInt(bubbles.size())).letter=target;
            invalidate();
            postDelayed(this,35);
        }

        @Override protected void onDraw(Canvas c) {
            p.setColor(0xffffffff);
            c.drawRoundRect(new RectF(0,dp(8),getWidth(),getHeight()-dp(5)),dp(22),dp(22),p);
            p.setColor(DARK);
            p.setTextAlign(Paint.Align.CENTER);
            p.setTypeface(Typeface.DEFAULT_BOLD);
            p.setTextSize(dp(18));
            c.drawText("ابحث عن الحرف:  "+target,getWidth()/2f,dp(42),p);
            for(Bubble b:bubbles){
                p.setColor(0x22000000);c.drawCircle(b.x,b.y+dp(4),b.r,p);
                p.setColor(b.color);c.drawCircle(b.x,b.y,b.r,p);
                p.setColor(0x55ffffff);c.drawCircle(b.x-b.r*.30f,b.y-b.r*.30f,b.r*.18f,p);
                p.setColor(Color.WHITE);p.setTextSize(b.r*.88f);
                Paint.FontMetrics fm=p.getFontMetrics();
                c.drawText(b.letter,b.x,b.y-(fm.ascent+fm.descent)/2f,p);
            }
        }

        @Override public boolean onTouchEvent(MotionEvent event) {
            if(event.getAction()!=MotionEvent.ACTION_UP)return true;
            for(Bubble b:bubbles){
                float dx=event.getX()-b.x,dy=event.getY()-b.y;
                if(dx*dx+dy*dy<=b.r*b.r){
                    if(b.letter.equals(target)){
                        win(2,"أحسنت! وجدت الحرف "+target);
                        target=letters[random.nextInt(letters.length)];
                        b.letter=target;
                        b.y=getHeight()-b.r;
                    }else miss();
                    invalidate();
                    return true;
                }
            }
            return true;
        }

        private final class Bubble {
            float x,y,r,speed; int color; String letter;
        }
    }
}
