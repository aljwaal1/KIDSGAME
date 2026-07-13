package com.explapp.kidsgame.legacy;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.os.Bundle;
import android.view.Gravity;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.GridLayout;
import android.widget.LinearLayout;
import android.widget.TextView;

public class MainActivity extends Activity {
    private LinearLayout root;
    private InteractionSound sounds;
    private boolean xTurn = true;
    private final Button[] cells = new Button[9];
    private TextView status;
    private Button soundButton;

    private final int purple = Color.rgb(91, 44, 131);
    private final int orange = Color.rgb(255, 138, 0);
    private final int cream = Color.rgb(255, 248, 225);

    @Override public void onCreate(Bundle state) {
        super.onCreate(state);
        sounds = new InteractionSound(this);
        showHome();
    }

    private TextView title(String text, int size) {
        TextView view = new TextView(this);
        view.setText(text);
        view.setTextSize(size);
        view.setTextColor(Color.WHITE);
        view.setGravity(Gravity.CENTER);
        view.setPadding(12, 18, 12, 18);
        return view;
    }

    private Button button(String text) {
        Button button = new Button(this);
        button.setText(text);
        button.setTextSize(20);
        button.setTextColor(purple);
        button.setAllCaps(false);
        button.setBackground(round(Color.WHITE, 24));
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(-1, 0, 1);
        params.setMargins(18, 10, 18, 10);
        button.setLayoutParams(params);
        return button;
    }

    private GradientDrawable round(int color, int radius) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(color);
        drawable.setCornerRadius(radius);
        drawable.setStroke(3, orange);
        return drawable;
    }

    private void base() {
        root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setGravity(Gravity.CENTER);
        root.setPadding(14, 20, 14, 20);
        root.setBackgroundColor(purple);
        setContentView(root);
    }

    private void addSoundToggle() {
        soundButton = new Button(this);
        soundButton.setAllCaps(false);
        soundButton.setTextSize(16);
        soundButton.setText(sounds.isEnabled() ? "🔊 الصوت يعمل" : "🔇 الصوت مكتوم");
        soundButton.setOnClickListener(view -> {
            boolean enabled = sounds.toggle();
            soundButton.setText(enabled ? "🔊 الصوت يعمل" : "🔇 الصوت مكتوم");
        });
        root.addView(soundButton, new LinearLayout.LayoutParams(-1, -2));
    }

    private void showHome() {
        base();
        root.addView(title("★ ملعب الأطفال ★\nنسخة الأجهزة القديمة", 28));
        addSoundToggle();

        Button xo = button("إكس أو");
        xo.setOnClickListener(view -> {
            sounds.play(InteractionSound.NAVIGATE);
            showXO();
        });
        root.addView(xo);

        Button numbers = button("تحدي الأرقام");
        numbers.setOnClickListener(view -> {
            sounds.play(InteractionSound.NAVIGATE);
            showNumbers();
        });
        root.addView(numbers);

        Button letters = button("حروف عربية");
        letters.setOnClickListener(view -> {
            sounds.play(InteractionSound.NAVIGATE);
            showLetters();
        });
        root.addView(letters);
        root.addView(title("Android 4.4+ • يعمل بدون إنترنت", 15));
    }

    private void back() {
        Button button = new Button(this);
        button.setAllCaps(false);
        button.setText("العودة للرئيسية");
        button.setOnClickListener(view -> {
            sounds.play(InteractionSound.NAVIGATE);
            showHome();
        });
        root.addView(button, new LinearLayout.LayoutParams(-1, -2));
    }

    private void showXO() {
        base();
        xTurn = true;
        status = title("دور X", 24);
        root.addView(status);

        GridLayout grid = new GridLayout(this);
        grid.setColumnCount(3);
        for (int i = 0; i < 9; i++) {
            final int index = i;
            cells[i] = new Button(this);
            cells[i].setTextSize(34);
            cells[i].setBackground(round(cream, 16));
            GridLayout.LayoutParams params = new GridLayout.LayoutParams();
            params.width = 0;
            params.height = 150;
            params.columnSpec = GridLayout.spec(i % 3, 1f);
            params.setMargins(5, 5, 5, 5);
            cells[i].setLayoutParams(params);
            cells[i].setOnClickListener(view -> move(index));
            grid.addView(cells[i]);
        }
        root.addView(grid, new LinearLayout.LayoutParams(-1, 0, 1));

        Button restart = new Button(this);
        restart.setAllCaps(false);
        restart.setText("إعادة الجولة");
        restart.setOnClickListener(view -> {
            sounds.play(InteractionSound.RESTART);
            showXO();
        });
        root.addView(restart, new LinearLayout.LayoutParams(-1, -2));
        back();
    }

    private void move(int index) {
        if (cells[index].getText().length() > 0 || isRoundFinished()) {
            sounds.play(InteractionSound.WRONG);
            return;
        }

        cells[index].setText(xTurn ? "X" : "O");
        sounds.play(xTurn ? InteractionSound.MOVE_X : InteractionSound.MOVE_O);

        String winner = winner();
        if (winner != null) {
            status.setText("فاز " + winner + " 🎉");
            sounds.play(InteractionSound.WIN);
            return;
        }

        if (boardIsFull()) {
            status.setText("تعادل جميل!");
            sounds.play(InteractionSound.DRAW);
            return;
        }

        xTurn = !xTurn;
        status.setText("دور " + (xTurn ? "X" : "O"));
    }

    private boolean isRoundFinished() {
        String text = status == null ? "" : status.getText().toString();
        return text.startsWith("فاز") || text.startsWith("تعادل");
    }

    private boolean boardIsFull() {
        for (Button cell : cells) if (cell.getText().length() == 0) return false;
        return true;
    }

    private String winner() {
        int[][] lines = {
                {0, 1, 2}, {3, 4, 5}, {6, 7, 8},
                {0, 3, 6}, {1, 4, 7}, {2, 5, 8},
                {0, 4, 8}, {2, 4, 6}
        };
        for (int[] line : lines) {
            String value = cells[line[0]].getText().toString();
            if (value.length() > 0
                    && value.equals(cells[line[1]].getText().toString())
                    && value.equals(cells[line[2]].getText().toString())) return value;
        }
        return null;
    }

    private void showNumbers() {
        base();
        root.addView(title("اختر الرقم التالي", 25));
        final TextView score = title("1", 50);
        root.addView(score);

        for (int i = 2; i <= 5; i++) {
            final int number = i;
            Button choice = button("الرقم " + i);
            choice.setOnClickListener(view -> {
                int expected = Integer.parseInt(score.getText().toString()) + 1;
                if (number == expected) {
                    score.setText(String.valueOf(number));
                    sounds.play(number == 5 ? InteractionSound.WIN : InteractionSound.CORRECT);
                } else {
                    sounds.play(InteractionSound.WRONG);
                }
            });
            root.addView(choice);
        }
        back();
    }

    private void showLetters() {
        base();
        root.addView(title("اضغط الحرف واسمع نغمة", 25));
        String[] letters = {"أ", "ب", "ت", "ث", "ج", "ح", "خ", "د", "ر", "س", "ش", "ص", "ط", "ع", "ف", "ق", "ك", "ل", "م", "ن", "ه", "و", "ي"};
        GridLayout grid = new GridLayout(this);
        grid.setColumnCount(4);
        for (int i = 0; i < letters.length; i++) {
            final int tone = i;
            Button letter = new Button(this);
            letter.setText(letters[i]);
            letter.setTextSize(26);
            letter.setOnClickListener(view -> sounds.play(tone % 2 == 0 ? InteractionSound.MOVE_X : InteractionSound.MOVE_O));
            grid.addView(letter, new ViewGroup.LayoutParams(150, 105));
        }
        root.addView(grid, new LinearLayout.LayoutParams(-1, 0, 1));
        back();
    }

    @Override public void onBackPressed() {
        sounds.play(InteractionSound.NAVIGATE);
        showHome();
    }

    @Override protected void onDestroy() {
        sounds.release();
        super.onDestroy();
    }
}
