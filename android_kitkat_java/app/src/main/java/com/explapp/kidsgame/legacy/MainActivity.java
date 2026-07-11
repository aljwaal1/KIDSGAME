package com.explapp.kidsgame.legacy;

import android.app.*;
import android.os.*;
import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.media.ToneGenerator;
import android.media.AudioManager;
import android.view.*;
import android.widget.*;

public class MainActivity extends Activity {
  LinearLayout root; ToneGenerator tones; boolean xTurn=true; Button[] cells=new Button[9]; TextView status;
  int purple=Color.rgb(91,44,131), orange=Color.rgb(255,138,0), cream=Color.rgb(255,248,225);

  @Override public void onCreate(Bundle b){super.onCreate(b); tones=new ToneGenerator(AudioManager.STREAM_MUSIC,65); showHome();}
  TextView title(String text,int size){TextView v=new TextView(this);v.setText(text);v.setTextSize(size);v.setTextColor(Color.WHITE);v.setGravity(Gravity.CENTER);v.setPadding(12,18,12,18);return v;}
  Button button(String text){Button b=new Button(this);b.setText(text);b.setTextSize(20);b.setTextColor(purple);b.setAllCaps(false);b.setBackground(round(Color.WHITE,24));LinearLayout.LayoutParams p=new LinearLayout.LayoutParams(-1,0,1);p.setMargins(18,10,18,10);b.setLayoutParams(p);return b;}
  GradientDrawable round(int color,int radius){GradientDrawable g=new GradientDrawable();g.setColor(color);g.setCornerRadius(radius);g.setStroke(3,orange);return g;}
  void base(){root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);root.setGravity(Gravity.CENTER);root.setPadding(14,20,14,20);root.setBackgroundColor(purple);setContentView(root);}
  void sound(boolean win){tones.startTone(win?ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD:ToneGenerator.TONE_PROP_BEEP,win?300:90);}
  void showHome(){base();root.addView(title("★ ملعب الأطفال ★\nنسخة الأجهزة القديمة",28));Button xo=button("إكس أو");xo.setOnClickListener(v->showXO());root.addView(xo);Button numbers=button("تحدي الأرقام");numbers.setOnClickListener(v->showNumbers());root.addView(numbers);Button letters=button("حروف عربية");letters.setOnClickListener(v->showLetters());root.addView(letters);root.addView(title("Android 4.4+ • يعمل بدون إنترنت",15));}
  void back(){Button b=new Button(this);b.setText("العودة للرئيسية");b.setOnClickListener(v->showHome());root.addView(b,new LinearLayout.LayoutParams(-1,-2));}
  void showXO(){base();status=title("دور X",24);root.addView(status);GridLayout grid=new GridLayout(this);grid.setColumnCount(3);for(int i=0;i<9;i++){final int n=i;cells[i]=new Button(this);cells[i].setTextSize(34);cells[i].setBackground(round(cream,16));GridLayout.LayoutParams p=new GridLayout.LayoutParams();p.width=0;p.height=150;p.columnSpec=GridLayout.spec(i%3,1f);p.setMargins(5,5,5,5);cells[i].setLayoutParams(p);cells[i].setOnClickListener(v->move(n));grid.addView(cells[i]);}root.addView(grid,new LinearLayout.LayoutParams(-1,0,1));back();}
  void move(int n){if(cells[n].getText().length()>0||status.getText().toString().startsWith("فاز"))return;cells[n].setText(xTurn?"X":"O");sound(false);String w=winner();if(w!=null){status.setText("فاز "+w+" 🎉");sound(true);}else{xTurn=!xTurn;status.setText("دور "+(xTurn?"X":"O"));}}
  String winner(){int[][] l={{0,1,2},{3,4,5},{6,7,8},{0,3,6},{1,4,7},{2,5,8},{0,4,8},{2,4,6}};for(int[] a:l){String s=cells[a[0]].getText().toString();if(s.length()>0&&s.equals(cells[a[1]].getText().toString())&&s.equals(cells[a[2]].getText().toString()))return s;}return null;}
  void showNumbers(){base();root.addView(title("اختر الرقم التالي",25));final TextView score=title("1",50);root.addView(score);for(int i=2;i<=5;i++){final int n=i;Button b=button("الرقم "+i);b.setOnClickListener(v->{int expected=Integer.parseInt(score.getText().toString())+1;if(n==expected){score.setText(""+n);sound(n==5);}else sound(false);});root.addView(b);}back();}
  void showLetters(){base();root.addView(title("اضغط الحرف واسمع نغمة",25));String[] a={"أ","ب","ت","ث","ج","ح","خ","د","ر","س","ش","ص","ط","ع","ف","ق","ك","ل","م","ن","ه","و","ي"};GridLayout g=new GridLayout(this);g.setColumnCount(4);for(String s:a){Button b=new Button(this);b.setText(s);b.setTextSize(26);b.setOnClickListener(v->sound(false));g.addView(b,new ViewGroup.LayoutParams(150,105));}root.addView(g,new LinearLayout.LayoutParams(-1,0,1));back();}
  @Override public void onBackPressed(){showHome();}
  @Override protected void onDestroy(){tones.release();super.onDestroy();}
}
