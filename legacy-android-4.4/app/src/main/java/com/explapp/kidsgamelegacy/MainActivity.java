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
import android.os.Build;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Random;

/** A fast, fully offline Java game arena designed for Android 4.4 and small screens. */
public final class MainActivity extends Activity {
    private static final String PREFS="kids_arena_v2";
    private final Random random=new Random();
    private final android.os.Handler handler=new android.os.Handler();
    private SharedPreferences prefs;
    private int stars,rounds,bestStreak,streak;
    private boolean home=true;
    private final String[] xo=new String[9];
    private String xoTurn="X";
    private int memoryFirst=-1,memorySecond=-1,memoryMatches;
    private String[] memoryCards;
    private boolean[] memoryOpen;

    @Override public void onCreate(Bundle state){
        super.onCreate(state);
        prefs=getSharedPreferences(PREFS,MODE_PRIVATE);
        stars=prefs.getInt("stars",0);rounds=prefs.getInt("rounds",0);bestStreak=prefs.getInt("best",0);
        showHome();
    }

    private void showHome(){
        handler.removeCallbacksAndMessages(null);
        home=true;
        LinearLayout root=page();
        ArenaArt hero=new ArenaArt(this);root.addView(hero,new LinearLayout.LayoutParams(-1,dp(145)));
        TextView title=text("ملعب الأطفال",30,0xff3b247b,true);title.setGravity(Gravity.CENTER);root.addView(title,top(6));
        TextView sub=text("ألعب، فكّر، وتعلّم دون إنترنت",16,0xff64748b,true);sub.setGravity(Gravity.CENTER);root.addView(sub,match());
        LinearLayout stats=row();stats.addView(pill("النجوم  "+stars),weight());stats.addView(gap(7));stats.addView(pill("الجولات  "+rounds),weight());stats.addView(gap(7));stats.addView(pill("أفضل سلسلة  "+bestStreak),weight());root.addView(stats,top(10));
        root.addView(gameRow(gameButton("الألوان","لاحظ واختر",0xffef4444,new View.OnClickListener(){@Override public void onClick(View v){showColorGame();}}),gameButton("الحساب السريع","جمع وطرح",0xff7c3aed,new View.OnClickListener(){@Override public void onClick(View v){showMathGame();}})),top(12));
        root.addView(gameRow(gameButton("ابحث عن المختلف","قوة الملاحظة",0xff0f9f91,new View.OnClickListener(){@Override public void onClick(View v){showOddGame();}}),gameButton("أكمل النمط","تفكير منطقي",0xff1687c3,new View.OnClickListener(){@Override public void onClick(View v){showPatternGame();}})),top(8));
        root.addView(gameRow(gameButton("ذاكرة البطاقات","طابق الأزواج",0xffd14b75,new View.OnClickListener(){@Override public void onClick(View v){startMemory();}}),gameButton("إكس أو","لاعبان",0xfff07c23,new View.OnClickListener(){@Override public void onClick(View v){startXo();}})),top(8));
        Button reset=smallButton("إعادة ضبط التقدم",0xff64748b);reset.setOnClickListener(new View.OnClickListener(){@Override public void onClick(View v){confirmReset();}});root.addView(reset,top(12));
        setPage(root);
    }

    private void showColorGame(){
        home=false;final String[] names={"أحمر","أزرق","أخضر","أصفر","بنفسجي","برتقالي"};final int[] colors={0xffef4444,0xff1687c3,0xff22a75a,0xffffbd20,0xff7c3aed,0xfff07c23};final int target=random.nextInt(names.length);
        LinearLayout root=gamePage("لعبة الألوان","اختر اسم لون الدائرة",0xffef4444);
        ColorDisc disc=new ColorDisc(this,colors[target]);root.addView(disc,new LinearLayout.LayoutParams(-1,dp(170)));
        List<Integer> options=indices(names.length,4,target);
        for(int i=0;i<options.size();i+=2){LinearLayout line=row();for(int j=i;j<Math.min(i+2,options.size());j++){final int pick=options.get(j);Button b=answerButton(names[pick],colors[pick]);b.setOnClickListener(new View.OnClickListener(){@Override public void onClick(View v){if(pick==target){win(2,"رائع! عرفت اللون");showColorGame();}else miss();}});line.addView(b,weight());if(j==i)line.addView(gap(8));}root.addView(line,top(7));}
        setPage(root);
    }

    private void showMathGame(){
        home=false;final boolean plus=random.nextBoolean();final int a=plus?random.nextInt(10)+1:random.nextInt(9)+6;final int b=plus?random.nextInt(9)+1:random.nextInt(a-1)+1;final int result=plus?a+b:a-b;
        LinearLayout root=gamePage("الحساب السريع","كل إجابة صحيحة ترفع سلسلتك",0xff7c3aed);
        TextView problem=text(a+(plus?" + ":" - ")+b+" = ؟",43,0xff3b247b,true);problem.setGravity(Gravity.CENTER);problem.setPadding(dp(8),dp(30),dp(8),dp(30));problem.setBackground(round(0xffffffff,22));root.addView(problem,top(12));
        ArrayList<Integer> values=new ArrayList<Integer>();values.add(result);while(values.size()<4){int x=Math.max(0,result+random.nextInt(7)-3);if(!values.contains(x))values.add(x);}Collections.shuffle(values);
        for(int i=0;i<4;i+=2){LinearLayout line=row();for(int j=i;j<i+2;j++){final int pick=values.get(j);Button answer=answerButton(String.valueOf(pick),0xff7c3aed);answer.setOnClickListener(new View.OnClickListener(){@Override public void onClick(View v){if(pick==result){win(3,"إجابة صحيحة");showMathGame();}else miss();}});line.addView(answer,weight());if(j==i)line.addView(gap(8));}root.addView(line,top(8));}
        setPage(root);
    }

    private void showOddGame(){
        home=false;final String[] sets={"دائرة","مربع","نجمة","مثلث","قمر","شمس"};final String common=sets[random.nextInt(sets.length)];String odd;do{odd=sets[random.nextInt(sets.length)];}while(odd.equals(common));final String target=odd;final int oddAt=random.nextInt(6);
        LinearLayout root=gamePage("ابحث عن المختلف","خمس بطاقات متشابهة وواحدة مختلفة",0xff0f9f91);
        for(int i=0;i<6;i+=2){LinearLayout line=row();for(int j=i;j<i+2;j++){final int pick=j;Button b=answerButton(j==oddAt?odd:common,j==oddAt?0xfff59e0b:0xff0f9f91);b.setOnClickListener(new View.OnClickListener(){@Override public void onClick(View v){if(pick==oddAt){win(3,"ملاحظة ممتازة: "+target);showOddGame();}else miss();}});line.addView(b,weight());if(j==i)line.addView(gap(8));}root.addView(line,top(8));}
        setPage(root);
    }

    private void showPatternGame(){
        home=false;final int kind=random.nextInt(3);final String[] sequences={"1  2  1  2  1  ؟","2  4  6  8  ؟","1  1  2  1  1  ؟"};final int[] answers={2,10,2};final int result=answers[kind];
        LinearLayout root=gamePage("أكمل النمط","ما الرقم الذي يأتي بعد علامة السؤال؟",0xff1687c3);
        TextView sequence=text(sequences[kind],30,0xff123b65,true);sequence.setGravity(Gravity.CENTER);sequence.setPadding(dp(6),dp(28),dp(6),dp(28));sequence.setBackground(round(0xffffffff,22));root.addView(sequence,top(14));
        ArrayList<Integer> values=new ArrayList<Integer>();values.add(result);while(values.size()<4){int x=random.nextInt(11);if(!values.contains(x))values.add(x);}Collections.shuffle(values);
        LinearLayout line=row();for(final int pick:values){Button b=answerButton(String.valueOf(pick),0xff1687c3);b.setOnClickListener(new View.OnClickListener(){@Override public void onClick(View v){if(pick==result){win(3,"أكملت النمط");showPatternGame();}else miss();}});line.addView(b,weight());line.addView(gap(5));}root.addView(line,top(12));setPage(root);
    }

    private void startMemory(){
        List<String> cards=new ArrayList<String>(Arrays.asList("قمر","قمر","شمس","شمس","نجم","نجم"));Collections.shuffle(cards);memoryCards=cards.toArray(new String[6]);memoryOpen=new boolean[6];memoryFirst=memorySecond=-1;memoryMatches=0;showMemory();
    }

    private void showMemory(){
        home=false;LinearLayout root=gamePage("ذاكرة البطاقات","اكشف بطاقتين متشابهتين",0xffd14b75);
        for(int i=0;i<6;i+=2){LinearLayout line=row();for(int j=i;j<i+2;j++){final int index=j;Button b=answerButton(memoryOpen[index]?memoryCards[index]:"؟",memoryOpen[index]?0xffd14b75:0xff3b247b);b.setEnabled(memorySecond<0&&!memoryOpen[index]);b.setOnClickListener(new View.OnClickListener(){@Override public void onClick(View v){openMemory(index);}});line.addView(b,weight());if(j==i)line.addView(gap(8));}root.addView(line,top(8));}
        Button fresh=smallButton("خلط البطاقات من جديد",0xff64748b);fresh.setOnClickListener(new View.OnClickListener(){@Override public void onClick(View v){startMemory();}});root.addView(fresh,top(12));setPage(root);
    }

    private void openMemory(int index){
        memoryOpen[index]=true;if(memoryFirst<0){memoryFirst=index;showMemory();return;}memorySecond=index;showMemory();
        final int first=memoryFirst,second=memorySecond;handler.postDelayed(new Runnable(){@Override public void run(){
            if(memoryCards[first].equals(memoryCards[second])){memoryMatches++;memoryFirst=memorySecond=-1;if(memoryMatches==3){win(6,"أكملت جميع الأزواج");startMemory();}else showMemory();}
            else{memoryOpen[first]=memoryOpen[second]=false;memoryFirst=memorySecond=-1;streak=0;showMemory();}
        }},650);
    }

    private void startXo(){Arrays.fill(xo,"");xoTurn="X";showXo("دور اللاعب X");}
    private void showXo(String message){
        home=false;LinearLayout root=gamePage("إكس أو",message,0xfff07c23);
        for(int i=0;i<9;i+=3){LinearLayout line=row();for(int j=i;j<i+3;j++){final int index=j;Button b=answerButton(xo[j].length()==0?" ":xo[j],xo[j].equals("O")?0xfff07c23:0xff6d28d9);b.setTextSize(31);b.setEnabled(xo[j].length()==0);b.setOnClickListener(new View.OnClickListener(){@Override public void onClick(View v){xoMove(index);}});line.addView(b,weight());if(j<i+2)line.addView(gap(6));}root.addView(line,top(6));}
        Button fresh=smallButton("جولة جديدة",0xff64748b);fresh.setOnClickListener(new View.OnClickListener(){@Override public void onClick(View v){startXo();}});root.addView(fresh,top(12));setPage(root);
    }

    private void xoMove(int index){
        xo[index]=xoTurn;if(xoWinner(xoTurn)){win(5,"فاز اللاعب "+xoTurn);startXo();return;}boolean full=true;for(String s:xo)if(s.length()==0)full=false;if(full){rounds++;save();toast("تعادل رائع");startXo();return;}xoTurn=xoTurn.equals("X")?"O":"X";showXo("دور اللاعب "+xoTurn);
    }
    private boolean xoWinner(String s){int[][] lines={{0,1,2},{3,4,5},{6,7,8},{0,3,6},{1,4,7},{2,5,8},{0,4,8},{2,4,6}};for(int[] x:lines)if(xo[x[0]].equals(s)&&xo[x[1]].equals(s)&&xo[x[2]].equals(s))return true;return false;}

    private LinearLayout gamePage(String title,String subtitle,int color){
        LinearLayout root=page();Button back=smallButton("العودة إلى الألعاب",0xff64748b);back.setOnClickListener(new View.OnClickListener(){@Override public void onClick(View v){showHome();}});root.addView(back,match());
        TextView header=text(title+"\n"+subtitle,23,Color.WHITE,true);header.setGravity(Gravity.CENTER);header.setPadding(dp(10),dp(17),dp(10),dp(17));header.setBackground(round(color,22));root.addView(header,top(8));
        TextView status=text("النجوم: "+stars+"   •   السلسلة: "+streak,15,0xff475569,true);status.setGravity(Gravity.CENTER);root.addView(status,top(8));return root;
    }

    private void win(int reward,String message){stars+=reward;rounds++;streak++;if(streak>bestStreak)bestStreak=streak;save();toast(message+"  +"+reward+" نجوم");}
    private void miss(){streak=0;save();toast("حاول مرة أخرى");}
    private void save(){prefs.edit().putInt("stars",stars).putInt("rounds",rounds).putInt("best",bestStreak).apply();}
    private void confirmReset(){new AlertDialog.Builder(this).setTitle("إعادة ضبط التقدم").setMessage("هل تريد حذف النجوم والجولات؟").setPositiveButton("إعادة",new DialogInterface.OnClickListener(){@Override public void onClick(DialogInterface d,int w){stars=rounds=bestStreak=streak=0;save();showHome();}}).setNegativeButton("إلغاء",null).show();}

    private List<Integer> indices(int size,int count,int required){ArrayList<Integer> all=new ArrayList<Integer>();for(int i=0;i<size;i++)all.add(i);Collections.shuffle(all);if(!all.subList(0,count).contains(required)){all.remove((Integer)required);all.set(count-1,required);}return new ArrayList<Integer>(all.subList(0,count));}
    private LinearLayout gameRow(Button a,Button b){LinearLayout row=row();row.addView(a,weight());row.addView(gap(8));row.addView(b,weight());return row;}
    private Button gameButton(String title,String sub,int color,View.OnClickListener listener){Button b=button(title+"\n"+sub,color);b.setTextSize(16);b.setMinHeight(dp(70));b.setOnClickListener(listener);return b;}
    private Button answerButton(String value,int color){Button b=button(value,color);b.setTextSize(20);b.setMinHeight(dp(66));return b;}
    private Button button(String value,int color){Button b=new Button(this);b.setText(value);b.setAllCaps(false);b.setTextColor(Color.WHITE);b.setTextSize(17);b.setTypeface(Typeface.DEFAULT,Typeface.BOLD);b.setGravity(Gravity.CENTER);b.setMinHeight(dp(56));b.setBackground(round(color,17));if(Build.VERSION.SDK_INT>=21)b.setElevation(dp(3));return b;}
    private Button smallButton(String value,int color){Button b=button(value,color);b.setTextSize(14);b.setMinHeight(dp(46));return b;}
    private TextView text(String value,int size,int color,boolean bold){TextView v=new TextView(this);v.setText(value);v.setTextSize(size);v.setTextColor(color);v.setTypeface(Typeface.DEFAULT,bold?Typeface.BOLD:Typeface.NORMAL);return v;}
    private TextView pill(String value){TextView v=text(value,13,0xff3b247b,true);v.setGravity(Gravity.CENTER);v.setPadding(dp(3),dp(10),dp(3),dp(10));v.setBackground(round(0xffffffff,50));return v;}
    private LinearLayout page(){LinearLayout root=new LinearLayout(this);root.setOrientation(LinearLayout.VERTICAL);root.setPadding(dp(12),dp(12),dp(12),dp(22));if(Build.VERSION.SDK_INT>=17)root.setLayoutDirection(View.LAYOUT_DIRECTION_RTL);return root;}
    private void setPage(LinearLayout root){ScrollView scroll=new ScrollView(this);scroll.setFillViewport(true);scroll.setBackgroundColor(0xfff5f3ff);scroll.addView(root);setContentView(scroll);}
    private LinearLayout row(){LinearLayout row=new LinearLayout(this);row.setOrientation(LinearLayout.HORIZONTAL);row.setGravity(Gravity.CENTER);return row;}
    private GradientDrawable round(int color,int radius){GradientDrawable d=new GradientDrawable();d.setColor(color);d.setCornerRadius(dp(radius));return d;}
    private View gap(int width){View v=new View(this);v.setLayoutParams(new LinearLayout.LayoutParams(dp(width),1));return v;}
    private LinearLayout.LayoutParams weight(){return new LinearLayout.LayoutParams(0,-2,1f);}
    private LinearLayout.LayoutParams match(){return new LinearLayout.LayoutParams(-1,-2);}
    private LinearLayout.LayoutParams top(int margin){LinearLayout.LayoutParams p=match();p.topMargin=dp(margin);return p;}
    private int dp(int n){return(int)(n*getResources().getDisplayMetrics().density+.5f);}
    private void toast(String value){Toast.makeText(this,value,Toast.LENGTH_SHORT).show();}
    @Override public void onBackPressed(){if(home)super.onBackPressed();else showHome();}

    private static final class ColorDisc extends View{
        final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);final int color;ColorDisc(MainActivity c,int value){super(c);color=value;}
        @Override protected void onDraw(Canvas c){float x=getWidth()/2f,y=getHeight()/2f,r=Math.min(getWidth(),getHeight())*.34f;p.setColor(0x22000000);c.drawCircle(x,y+10,r,p);p.setColor(color);c.drawCircle(x,y,r,p);p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(7);p.setColor(Color.WHITE);c.drawCircle(x,y,r*.78f,p);p.setStyle(Paint.Style.FILL);}
    }
    private static final class ArenaArt extends View{
        final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);final Path path=new Path();ArenaArt(MainActivity c){super(c);}
        @Override protected void onDraw(Canvas c){float w=getWidth(),h=getHeight();p.setColor(0xff6d28d9);c.drawRoundRect(new RectF(0,0,w,h),28,28,p);p.setColor(0xff06b6d4);c.drawCircle(w*.12f,h*.2f,h*.22f,p);c.drawCircle(w*.9f,h*.78f,h*.31f,p);float x=w*.5f,y=h*.52f,r=h*.34f;path.reset();for(int i=0;i<10;i++){double a=-Math.PI/2+i*Math.PI/5;float rr=i%2==0?r:r*.45f;float px=x+(float)Math.cos(a)*rr,py=y+(float)Math.sin(a)*rr;if(i==0)path.moveTo(px,py);else path.lineTo(px,py);}path.close();p.setColor(0xffffd45c);c.drawPath(path,p);p.setColor(0xff3b247b);c.drawCircle(x-r*.27f,y-r*.05f,r*.07f,p);c.drawCircle(x+r*.27f,y-r*.05f,r*.07f,p);p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(5);c.drawArc(new RectF(x-r*.32f,y,x+r*.32f,y+r*.38f),10,160,false,p);p.setStyle(Paint.Style.FILL);}
    }
}
