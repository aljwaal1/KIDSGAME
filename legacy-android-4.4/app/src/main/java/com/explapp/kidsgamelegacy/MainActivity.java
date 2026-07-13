package com.explapp.kidsgamelegacy;

import android.app.*;
import android.content.*;
import android.graphics.*;
import android.graphics.drawable.GradientDrawable;
import android.os.*;
import android.view.*;
import android.widget.*;
import java.util.*;

public final class MainActivity extends Activity {
    private static final int COLORS=1,SHAPES=2,COUNTING=3,COMPARE=4;
    private final Random random=new Random();
    private SharedPreferences prefs;
    private int stars,streak,best,played,gameType,target;
    private LinearLayout root,answers;
    private TextView starsView,question,feedback;
    private GamePicture picture;

    @Override public void onCreate(Bundle state){super.onCreate(state);prefs=getSharedPreferences("kids_v2",MODE_PRIVATE);load();showHome();}

    private void showHome(){
        gameType=0;
        ScrollView scroll=new ScrollView(this);root=base();scroll.addView(root);
        LinearLayout stats=row();starsView=badge("النجوم "+stars);stats.addView(starsView,weight());stats.addView(gap());stats.addView(badge("أفضل سلسلة "+best),weight());root.addView(stats,match());
        TextView title=text("ملعب الأطفال",31,0xff153a63,true);title.setGravity(Gravity.CENTER);root.addView(title,top(10));
        TextView sub=text("أربع ألعاب تعليمية تعمل دون إنترنت",16,0xff486c7a,false);sub.setGravity(Gravity.CENTER);root.addView(sub,top(3));
        GamePicture hero=new GamePicture(this);hero.mode=0;root.addView(hero,new LinearLayout.LayoutParams(-1,dp(210)));
        addMenu("لعبة الألوان","تعرف إلى الألوان الأساسية",COLORS,0xffef5350);
        addMenu("الأشكال المرحة","دائرة ومربع ومثلث ونجمة",SHAPES,0xff7e57c2);
        addMenu("عدّ النجوم","عد من واحد إلى عشرة",COUNTING,0xff2e9d58);
        addMenu("الأكبر والأصغر","قارن بين مجموعتين",COMPARE,0xff1687c3);
        Button reset=button("تصفير التقدم",0xff607d8b);reset.setOnClickListener(new View.OnClickListener(){public void onClick(View v){confirmReset();}});root.addView(reset,top(12));
        setContentView(scroll);
    }

    private void addMenu(String title,String subtitle,final int type,int color){
        Button b=button(title+"\n"+subtitle,color);b.setMinHeight(dp(68));b.setOnClickListener(new View.OnClickListener(){public void onClick(View v){gameType=type;newRound();}});root.addView(b,top(8));
    }

    private void newRound(){
        if(gameType==0){showHome();return;}
        ScrollView scroll=new ScrollView(this);root=base();scroll.addView(root);
        LinearLayout head=row();Button back=button("القائمة",0xff607d8b);back.setOnClickListener(new View.OnClickListener(){public void onClick(View v){showHome();}});head.addView(back,weight());head.addView(gap());starsView=badge("النجوم "+stars+"  |  السلسلة "+streak);head.addView(starsView,new LinearLayout.LayoutParams(0,dp(54),1.6f));root.addView(head,match());
        question=text("",25,0xff153a63,true);question.setGravity(Gravity.CENTER);root.addView(question,top(10));
        picture=new GamePicture(this);picture.mode=gameType;root.addView(picture,new LinearLayout.LayoutParams(-1,dp(260)));
        answers=new LinearLayout(this);answers.setOrientation(LinearLayout.VERTICAL);root.addView(answers,top(8));
        feedback=text("اختر الإجابة الصحيحة",17,0xff486c7a,true);feedback.setGravity(Gravity.CENTER);root.addView(feedback,top(8));
        buildQuestion();setContentView(scroll);
    }

    private void buildQuestion(){
        answers.removeAllViews();feedback.setText("اختر الإجابة الصحيحة");
        if(gameType==COLORS){
            String[] names={"أحمر","أزرق","أخضر","أصفر","برتقالي","بنفسجي"};
            int[] colors={0xffe53935,0xff1e88e5,0xff43a047,0xffffc107,0xfff57c00,0xff8e24aa};
            target=random.nextInt(names.length);picture.value=target;picture.color=colors[target];question.setText("ما لون الدائرة؟");addChoices(names,target,4);
        }else if(gameType==SHAPES){
            String[] names={"دائرة","مربع","مثلث","نجمة"};target=random.nextInt(4);picture.value=target;picture.color=new int[]{0xff26a69a,0xff7e57c2,0xffff7043,0xffffb300}[target];question.setText("ما اسم هذا الشكل؟");addChoices(names,target,4);
        }else if(gameType==COUNTING){
            target=1+random.nextInt(10);picture.value=target;picture.color=0xffffb300;question.setText("كم نجمة ترى؟");addNumberChoices(target);
        }else{
            int left=1+random.nextInt(8),right=1+random.nextInt(8);while(right==left)right=1+random.nextInt(8);
            picture.value=left;picture.second=right;picture.color=0xff1687c3;target=left>right?0:1;question.setText("أي مجموعة فيها عدد أكبر؟");
            addAnswer("المجموعة اليمنى",0);addAnswer("المجموعة اليسرى",1);
        }
        picture.invalidate();
    }

    private void addChoices(String[] all,int correct,int count){
        ArrayList<Integer> list=new ArrayList<Integer>();list.add(correct);
        while(list.size()<count){int x=random.nextInt(all.length);if(!list.contains(x))list.add(x);}
        Collections.shuffle(list);for(Integer x:list)addAnswer(all[x],x);
    }

    private void addNumberChoices(int correct){
        ArrayList<Integer> list=new ArrayList<Integer>();list.add(correct);
        while(list.size()<4){int x=1+random.nextInt(10);if(!list.contains(x))list.add(x);}
        Collections.shuffle(list);for(Integer x:list)addAnswer(String.valueOf(x),x);
    }

    private void addAnswer(String label,final int value){
        Button b=button(label,0xff246ba0);b.setOnClickListener(new View.OnClickListener(){public void onClick(View v){answer(value);}});answers.addView(b,top(6));
    }

    private void answer(int value){
        played++;
        if(value==target){
            int earned=GameRules.starsFor(streak);stars+=earned;streak++;best=Math.max(best,streak);
            feedback.setText("أحسنت! إجابة صحيحة  +"+earned+" نجوم");feedback.setTextColor(0xff248f4c);save();
            disableAnswers();answers.postDelayed(new Runnable(){public void run(){newRound();}},700);
        }else{
            streak=0;feedback.setText("ليست صحيحة، حاول مرة أخرى");feedback.setTextColor(0xffd14646);save();
        }
        starsView.setText("النجوم "+stars+"  |  السلسلة "+streak);
    }

    private void disableAnswers(){for(int i=0;i<answers.getChildCount();i++)answers.getChildAt(i).setEnabled(false);}

    private void confirmReset(){new AlertDialog.Builder(this).setTitle("تصفير التقدم").setMessage("هل تريد حذف النجوم والسلسلة؟").setPositiveButton("حذف",new DialogInterface.OnClickListener(){public void onClick(DialogInterface d,int w){stars=streak=best=played=0;save();showHome();}}).setNegativeButton("إلغاء",null).show();}

    private void load(){stars=prefs.getInt("stars",0);streak=prefs.getInt("streak",0);best=prefs.getInt("best",0);played=prefs.getInt("played",0);}
    private void save(){prefs.edit().putInt("stars",stars).putInt("streak",streak).putInt("best",best).putInt("played",played).apply();}

    private LinearLayout base(){LinearLayout b=new LinearLayout(this);b.setOrientation(LinearLayout.VERTICAL);b.setPadding(dp(12),dp(12),dp(12),dp(20));b.setBackgroundColor(0xfffff8e8);if(Build.VERSION.SDK_INT>=17)b.setLayoutDirection(View.LAYOUT_DIRECTION_RTL);return b;}
    private LinearLayout row(){LinearLayout r=new LinearLayout(this);r.setOrientation(LinearLayout.HORIZONTAL);r.setGravity(Gravity.CENTER);return r;}
    private TextView text(String s,int size,int color,boolean bold){TextView v=new TextView(this);v.setText(s);v.setTextSize(size);v.setTextColor(color);v.setTypeface(Typeface.DEFAULT,bold?Typeface.BOLD:Typeface.NORMAL);return v;}
    private TextView badge(String s){TextView v=text(s,15,0xff153a63,true);v.setGravity(Gravity.CENTER);v.setPadding(dp(5),dp(10),dp(5),dp(10));v.setBackground(round(0xffffffff,50));return v;}
    private Button button(String s,int color){Button b=new Button(this);b.setText(s);b.setTextSize(17);b.setTextColor(Color.WHITE);b.setAllCaps(false);b.setTypeface(Typeface.DEFAULT,Typeface.BOLD);b.setGravity(Gravity.CENTER);b.setMinHeight(dp(54));b.setBackground(round(color,16));return b;}
    private GradientDrawable round(int color,int radius){GradientDrawable d=new GradientDrawable();d.setColor(color);d.setCornerRadius(dp(radius));return d;}
    private View gap(){View v=new View(this);v.setLayoutParams(new LinearLayout.LayoutParams(dp(7),1));return v;}
    private LinearLayout.LayoutParams match(){return new LinearLayout.LayoutParams(-1,-2);}
    private LinearLayout.LayoutParams weight(){return new LinearLayout.LayoutParams(0,-2,1);}
    private LinearLayout.LayoutParams top(int m){LinearLayout.LayoutParams p=match();p.topMargin=dp(m);return p;}
    private int dp(int x){return(int)(x*getResources().getDisplayMetrics().density+.5f);}

    @Override public void onBackPressed(){if(gameType!=0)showHome();else super.onBackPressed();}

    public static final class GameRules{
        private GameRules(){}
        public static int starsFor(int streak){return streak>=9?5:streak>=4?3:2;}
    }

    private static final class GamePicture extends View{
        final Paint p=new Paint(Paint.ANTI_ALIAS_FLAG);final Path path=new Path();int mode,value,second,color;
        GamePicture(Context c){super(c);}
        protected void onDraw(Canvas c){float w=getWidth(),h=getHeight(),s=Math.min(w,h);p.setStyle(Paint.Style.FILL);p.setColor(0xffdff4ff);c.drawRoundRect(new RectF(0,0,w,h),s*.08f,s*.08f,p);p.setColor(0xff8ed17d);c.drawOval(new RectF(-w*.1f,h*.72f,w*1.1f,h*1.1f),p);
            if(mode==0){drawStar(c,w*.25f,h*.35f,s*.12f,0xffffb300);drawStar(c,w*.5f,h*.25f,s*.16f,0xffef5350);drawStar(c,w*.75f,h*.38f,s*.12f,0xff1687c3);drawLabel(c,"العب وتعلم",w*.5f,h*.82f,s*.12f,0xff153a63);}
            else if(mode==COLORS){p.setColor(color);c.drawCircle(w*.5f,h*.48f,s*.28f,p);}
            else if(mode==SHAPES){p.setColor(color);if(value==0)c.drawCircle(w*.5f,h*.48f,s*.27f,p);else if(value==1)c.drawRect(w*.25f,h*.22f,w*.75f,h*.72f,p);else if(value==2){path.reset();path.moveTo(w*.5f,h*.16f);path.lineTo(w*.78f,h*.74f);path.lineTo(w*.22f,h*.74f);path.close();c.drawPath(path,p);}else drawStar(c,w*.5f,h*.46f,s*.3f,color);}
            else if(mode==COUNTING)drawDots(c,w,h,value);
            else{drawDotsArea(c,w*.08f,h*.15f,w*.43f,h*.78f,value,0xff1687c3);drawDotsArea(c,w*.57f,h*.15f,w*.92f,h*.78f,second,0xffef5350);}
        }
        void drawDots(Canvas c,float w,float h,int count){int cols=5;float r=Math.min(w/13f,h/7f);for(int i=0;i<count;i++){float x=w*.22f+(i%cols)*w*.14f,y=h*.28f+(i/cols)*h*.28f;drawStar(c,x,y,r,color);}}
        void drawDotsArea(Canvas c,float l,float t,float r,float b,int count,int col){float size=Math.min((r-l)/4f,(b-t)/4f);for(int i=0;i<count;i++)c.drawCircle(l+size+(i%3)*size*1.35f,t+size+(i/3)*size*1.35f,size*.42f,colPaint(col));}
        Paint colPaint(int col){p.setColor(col);return p;}
        void drawStar(Canvas c,float x,float y,float r,int col){p.setColor(col);path.reset();for(int i=0;i<10;i++){double a=-Math.PI/2+i*Math.PI/5;float rr=i%2==0?r:r*.45f;float px=x+(float)Math.cos(a)*rr,py=y+(float)Math.sin(a)*rr;if(i==0)path.moveTo(px,py);else path.lineTo(px,py);}path.close();c.drawPath(path,p);}
        void drawLabel(Canvas c,String v,float x,float y,float size,int col){p.setColor(col);p.setTextSize(size);p.setTextAlign(Paint.Align.CENTER);p.setFakeBoldText(true);c.drawText(v,x,y,p);p.setFakeBoldText(false);}
    }
}
