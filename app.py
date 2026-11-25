import streamlit as st
import requests
import json
from ddgs import DDGS
import edge_tts
import asyncio
import os
import time
import re
from io import BytesIO
from PIL import Image
import moviepy.editor as mpy

# ==========================================
# 1. إعدادات الصفحة والحالة (Session State)
# ==========================================
st.set_page_config(page_title="I.R.I.S System", page_icon="🤖", layout="wide")

if "messages" not in st.session_state:
    st.session_state.messages = []
if "persona" not in st.session_state:
    st.session_state.persona = None
if "balance" not in st.session_state:
    st.session_state.balance = 10.00  # رصيد تجريبي
if "subscription" not in st.session_state:
    st.session_state.subscription = "free"  # free, pro
if "daily_videos_used" not in st.session_state:
    st.session_state.daily_videos_used = 0

# المفاتيح (تتحط في Streamlit Secrets)
OPENROUTER_KEY = st.secrets.get("OPENROUTER_API_KEY", "")
REPLICATE_KEY = st.secrets.get("REPLICATE_API_TOKEN", "")

# ==========================================
# 2. العقل (OpenRouter)
# ==========================================
def ask_brain(system_prompt, user_prompt, model="deepseek/deepseek-chat", expect_json=False):
    try:
        res = requests.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers={"Authorization": f"Bearer {OPENROUTER_KEY}"},
            json={
                "model": model,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                "temperature": 0.7
            },
            timeout=40
        )
        if res.status_code == 200:
            content = res.json()["choices"][0]["message"]["content"]
            if expect_json:
                content = re.sub(r"```json|```", "", content).strip()
                return json.loads(content)
            return content
        return f"خطأ في العقل: {res.status_code}"
    except Exception as e:
        return f"مش قادر أوصل للعقل: {e}"

# ==========================================
# 3. البحث في الإنترنت
# ==========================================
def search_web(query):
    try:
        results = DDGS().text(query, max_results=3)
        return "".join([f"- {r['title']}: {r['body']}\n" for r in results])
    except:
        return ""

# ==========================================
# 4. أدوات Replicate (الصور والفيديو)
# ==========================================
def replicate_run(model_version, input_data):
    if not REPLICATE_KEY: return None
    try:
        res = requests.post(
            "https://api.replicate.com/v1/predictions",
            headers={"Authorization": f"Token {REPLICATE_KEY}", "Content-Type": "application/json"},
            json={"version": model_version, "input": input_data}
        )
        if res.status_code == 201:
            pred_url = res.json()["urls"]["get"]
            while True:
                status = requests.get(pred_url, headers={"Authorization": f"Token {REPLICATE_KEY}"}).json()
                if status["status"] == "succeeded":
                    return status["output"]
                elif status["status"] == "failed":
                    return None
                time.sleep(3)
    except:
        return None

def generate_image(prompt):
    version = "stability-ai/sdxl:39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b"
    output = replicate_run(version, {"prompt": prompt, "width": 1024, "height": 1024})
    return output[0] if output else None

def generate_video(prompt, duration=5, quality="fast"):
    # موديلات LTX-Video (أسرع وأرخص موديل فيديو)
    if quality == "fast":
        version = "lightricks/ltx-video:latest" 
        cost_per_sec = 0.03
    else:
        version = "lightricks/ltx-video:latest"
        cost_per_sec = 0.08
        
    duration = min(duration, 30) # الحد الأقصى 30 ثانية
    num_frames = duration * 25
    
    output = replicate_run(version, {"prompt": prompt, "num_frames": num_frames, "fps": 25})
    return output, cost_per_sec * duration

# ==========================================
# 5. توليد الصوت (Edge TTS)
# ==========================================
async def generate_voice(text, voice="ar-EG-ShakirNeural", filename="voice.mp3"):
    communicate = edge_tts.Communicate(text, voice)
    await communicate.save(filename)
    return filename

# ==========================================
# 6. مصنع الريلز (تعليمي / أطفال)
# ==========================================
def create_reel(topic, num_scenes, voice_gender):
    # 1. السيناريو
    prompt = f"""
    اكتب سيناريو فيديو تعليمي/أطفال عن: {topic}.
    قسّمه إلى {num_scenes} مشاهد.
    أرجع النتيجة بصيغة JSON فقط:
    {{ "title": "العنوان", "scenes": [ {{"image_prompt": "English description of image", "narrator": "النص العربي للراوي"}} ] }}
    """
    script_data = ask_brain("أنت كاتب سيناريو محترف.", prompt, expect_json=True)
    if not script_data or "scenes" not in script_data:
        return None, "فشل في كتابة السيناريو."

    clips = []
    voice = "ar-EG-ShakirNeural" if voice_gender == "ذكر" else "ar-EG-SalmaNeural"
    
    for i, scene in enumerate(script_data["scenes"]):
        # صورة
        img_url = generate_image(scene["image_prompt"])
        if not img_url: continue
        img_data = requests.get(img_url).content
        img_path = f"scene_{i}.jpg"
        with open(img_path, "wb") as f: f.write(img_data)
        
        # صوت
        audio_path = f"scene_{i}.mp3"
        asyncio.run(generate_voice(scene["narrator"], voice, audio_path))
        
        # مشهد
        audio_clip = mpy.AudioFileClip(audio_path)
        img_clip = mpy.ImageClip(img_path).set_duration(audio_clip.duration)
        img_clip = img_clip.set_audio(audio_clip)
        clips.append(img_clip)

    if not clips: return None, "فشل تجهيز المشاهد."
    
    # دمج
    final_video = mpy.concatenate_videoclips(clips, method="compose")
    out_path = f"reel_{int(time.time())}.mp4"
    final_video.write_videofile(out_path, fps=24, codec="libx264", audio_codec="aac")
    return out_path, script_data

# ==========================================
# 7. واجهة المستخدم
# ==========================================
st.title("🤖 I.R.I.S - Infinity Retinal Intelligence System")

# شاشة اختيار الشخصية
if st.session_state.persona is None:
    st.markdown("### أهلاً بك في نظام I.R.I.S. من أنت؟")
    col1, col2 = st.columns(2)
    if col1.button("👨‍💻 أنا ذكر (راكان)", use_container_width=True):
        st.session_state.persona = "rakan"
        st.rerun()
    if col2.button("👩‍💻 أنا أنثى (ليلى)", use_container_width=True):
        st.session_state.persona = "laila"
        st.rerun()
    st.stop()

is_rakan = st.session_state.persona == "rakan"
persona_name = "راكان" if is_rakan else "ليلى"
avatar = "👨‍💻" if is_rakan else "👩‍💻"

if is_rakan:
    base_prompt = "أنت راكان، مساعد ذكي. تتكلم بأسلوب رجولي صحوبي. سلاحك IRIS. ممنوع تقول إنك ذكاء اصطناعي."
else:
    base_prompt = "أنت ليلى، مساعدة ذكية. سلاحك أطلس (الدقة). تتكلمين بأسلوب بناتي ذكي. ممنوع تقولي إنك ذكاء اصطناعي."

# القائمة الجانبية (Sidebar)
with st.sidebar:
    st.markdown(f"### {avatar} {persona_name}")
    st.markdown(f"**الرصيد:** ${st.session_state.balance:.2f}")
    st.markdown(f"**الاشتراك:** {st.session_state.subscription.upper()}")
    st.markdown(f"**فيديوهات النهارده:** {st.session_state.daily_videos_used}/5")
    
    # الترقية والشحن
    if st.button("ترقية إلى Pro ($15/شهر)"):
        st.session_state.subscription = "pro"
        st.success("تمت الترقية!")
        st.rerun()
    if st.button("شحن $10"):
        st.session_state.balance += 10.00
        st.success("تم الشحن!")
        st.rerun()
        
    st.markdown("---")
    tool = st.radio("اختر أداة:", ["شات", "توليد صورة", "توليد فيديو", "كتابة كود", "🎬 مصنع الريلز"])
    
    if st.button("تغيير الشخصية / مسح الشات"):
        st.session_state.persona = None
        st.session_state.messages = []
        st.rerun()

# ==========================================
# 8. منطقة العمل (Tools)
# ==========================================

# --- 1. الشات ---
if tool == "شات":
    for msg in st.session_state.messages:
        with st.chat_message(msg["role"], avatar=avatar if msg["role"]=="assistant" else "🧑"):
            st.markdown(msg["content"])
            
    if prompt := st.chat_input(f"اكتب لـ {persona_name}..."):
        st.session_state.messages.append({"role": "user", "content": prompt})
        with st.chat_message("user", avatar="🧑"):
            st.markdown(prompt)
        with st.chat_message("assistant", avatar=avatar):
            placeholder = st.empty()
            placeholder.markdown(f"*{persona_name} بيدور...* 🔍")
            search = search_web(prompt)
            final_prompt = f"المستخدم قال: {prompt}\n"
            if search:
                final_prompt += f"لقيت: {search}\nرد بأسلوبك."
            reply = ask_brain(base_prompt, final_prompt)
            placeholder.markdown(reply)
            st.session_state.messages.append({"role": "assistant", "content": reply})

# --- 2. توليد صورة ---
elif tool == "توليد صورة":
    st.subheader("🎨 توليد صورة (التكلفة: $0.50)")
    img_prompt = st.text_input("وصف الصورة:")
    if st.button("توليد") and img_prompt:
        if st.session_state.balance >= 0.50:
            st.session_state.balance -= 0.50
            with st.spinner("جاري التوليد..."):
                url = generate_image(img_prompt)
                if url:
                    st.image(url, caption="الصورة")
                    img_data = requests.get(url).content
                    st.download_button("تحميل الصورة", img_data, "image.jpg", "image/jpeg")
                else:
                    st.error("فشل التوليد.")
        else:
            st.warning("رصيدك مش كفاية.")

# --- 3. توليد فيديو ---
elif tool == "توليد فيديو":
    st.subheader("🎬 توليد فيديو (حتى 30 ثانية)")
    duration = st.slider("المدة:", 5, 30, 10, 5)
    quality = st.radio("الجودة:", ["سريع (LTX-Video)", "احترافي (LTX-Pro)"])
    
    cost_per_sec = 0.03 if "سريع" in quality else 0.08
    total_cost = duration * cost_per_sec
    st.markdown(f"**التكلفة: ${total_cost:.2f}**")
    
    can_gen = False
    if st.session_state.subscription == "pro" and st.session_state.daily_videos_used < 5:
        can_gen = True
        st.info("✅ ضمن اشتراك Pro (5 فيديوهات يومياً).")
    elif st.session_state.balance >= total_cost:
        can_gen = True
        st.info(f"سيتم خصم ${total_cost:.2f}.")
    else:
        st.warning("رصيدك مش كفاية أو استنفدت حصتك اليومية.")
        
    vid_prompt = st.text_input("وصف الفيديو:")
    if st.button("توليد") and vid_prompt and can_gen:
        if st.session_state.subscription == "pro":
            st.session_state.daily_videos_used += 1
        else:
            st.session_state.balance -= total_cost
            
        with st.spinner("جاري توليد الفيديو... (ممكن ياخد دقيقة)"):
            url, _ = generate_video(vid_prompt, duration, quality)
            if url:
                st.video(url)
            else:
                st.error("فشل التوليد.")

# --- 4. كتابة كود ---
elif tool == "كتابة كود":
    st.subheader("💻 كتابة كود (DeepSeek Coder)")
    code_task = st.text_area("اطلب كود:")
    if st.button("تنفيذ") and code_task:
        with st.spinner("جاري كتابة الكود..."):
            reply = ask_brain("أنت مبرمج خبير. اكتب كود بايثون نظيف ومكتمل.", code_task, model="deepseek/deepseek-coder")
            st.code(reply, language="python")

# --- 5. مصنع الريلز ---
elif tool == "🎬 مصنع الريلز":
    st.subheader("🎬 توليد ريلز تعليمي / قصص أطفال")
    st.markdown("**التكلفة: $1.50 (يشمل الصور، الراوي، والمونتاج)**")
    
    topic = st.text_input("عن إيه الفيديو؟ (مثال: دورة المياه في الطبيعة)")
    scenes = st.number_input("عدد المشاهد:", min_value=2, max_value=5, value=3)
    voice = st.radio("صوت الراوي:", ["ذكر", "أنثى"])
    
    if st.button("صناعة الريل") and topic:
        if st.session_state.balance >= 1.50:
            st.session_state.balance -= 1.50
            with st.spinner("جاري كتابة السيناريو، توليد الصور، تسجيل الصوت، والمونتاج... (ممكن ياخد دقيقة أو دقيقتين)"):
                video_path, script = create_reel(topic, scenes, voice)
                if video_path:
                    st.success("تم إنشاء الفيديو بنجاح!")
                    st.video(video_path)
                    with open(video_path, "rb") as f:
                        st.download_button("تحميل الفيديو", f.read(), f"reel.mp4", "video/mp4")
                    with st.expander("عرض السيناريو"):
                        st.json(script)
                else:
                    st.error(f"فشل: {script}")
        else:
            st.warning("رصيدك مش كفاية.")
