package com.roadready.punjabi.demo;
import android.app.Activity;
import android.os.Bundle;
import android.content.Intent;
import android.speech.RecognizerIntent;
import android.speech.tts.TextToSpeech;
import android.webkit.JavascriptInterface;
import android.webkit.WebView;
import android.webkit.WebChromeClient;
import org.json.JSONObject;
import java.util.ArrayList;
import java.util.Locale;
public class MainActivity extends Activity {
 private WebView web;
 private TextToSpeech tts;
 @Override public void onCreate(Bundle b) {
  super.onCreate(b);
  getWindow().setStatusBarColor(0xFF142A43);
  getWindow().setNavigationBarColor(0xFF142A43);
  web=new WebView(this);
  web.getSettings().setJavaScriptEnabled(true);
  web.getSettings().setDomStorageEnabled(true);
  web.setWebChromeClient(new WebChromeClient());
  web.addJavascriptInterface(new Bridge(),"Android");
  setContentView(web);
  tts=new TextToSpeech(this, state -> {});
  web.loadUrl("file:///android_asset/index.html");
 }
 public class Bridge {
  @JavascriptInterface public void say(String text,String lang) {
   runOnUiThread(()->{
    if(tts==null)return;
    Locale locale=lang.equals("en")?Locale.UK:new Locale("pa","IN");
    int result=tts.setLanguage(locale);
    if(result==TextToSpeech.LANG_MISSING_DATA||result==TextToSpeech.LANG_NOT_SUPPORTED){
      web.evaluateJavascript("voiceUnavailable()",null);return;
    }
    tts.speak(text,TextToSpeech.QUEUE_FLUSH,null,"roadready");
   });
  }
  @JavascriptInterface public void listen() {
   runOnUiThread(()->{
    try {
      Intent i=new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
      i.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL,RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
      i.putExtra(RecognizerIntent.EXTRA_PROMPT,"Say A, B, C or D");
      startActivityForResult(i,220);
    } catch (Exception e) {web.evaluateJavascript("voiceUnavailable()",null);}
   });
  }
 }
 @Override protected void onActivityResult(int request,int result,Intent data) {
  super.onActivityResult(request,result,data);
  if(request==220 && result==RESULT_OK && data!=null) {
   ArrayList<String> texts=data.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS);
   if(texts!=null&&!texts.isEmpty()){
     web.evaluateJavascript("voiceAnswer("+JSONObject.quote(texts.get(0))+")",null);
   }
  }
 }
 @Override public void onBackPressed(){web.evaluateJavascript("backToHome()",null);}
 @Override protected void onDestroy(){if(tts!=null){tts.stop();tts.shutdown();}if(web!=null)web.destroy();super.onDestroy();}
}