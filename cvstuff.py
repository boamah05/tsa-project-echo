import cv2
from deepface import DeepFace
import time

def testCap() -> None:
    face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")

    capture = cv2.VideoCapture(0)

    if not capture.isOpened():
        raise Exception("Could Not Start Video Capture")

    while True:
        ret, frame = capture.read()
       
        if not ret:
            raise Exception("Could Not Return Frame")
       
       
        gray_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)


        faces = face_cascade.detectMultiScale(gray_frame, scaleFactor=1.1, minNeighbors=5, minSize=(30,30))

        for (x,y,w,h) in faces:
            face_roi = frame[y:y+h, x:x+w]
            result = DeepFace.analyze(face_roi, actions = ['emotion'], enforce_detection = False)

            emotion = result[0]["dominant_emotion"]

            cv2.rectangle(frame, (x,y), (x+w, y+h), (0,0,255), 2)
            cv2.putText(frame, emotion, (x,y-10), cv2.FONT_HERSHEY_SIMPLEX,0.9, (0,0,255),2)

        cv2.imshow("Emotion Prediction", frame)

        # Close From Loop When Pressed q
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    capture.release()
    cv2.destroyAllWindows()

def getEmotion() -> str | None:
    face_cascade = cv2.CascadeClassifier(
        cv2.data.haarcascades + "haarcascade_frontalface_default.xml"
    )

    capture = cv2.VideoCapture(0)

    if not capture.isOpened():
        raise Exception("Could Not Start Video Capture")

    emotion = None

    # warm up + try multiple frames
    for _ in range(10):
        ret, frame = capture.read()
        if not ret:
            continue

        gray_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

        faces = face_cascade.detectMultiScale(
            gray_frame,
            scaleFactor=1.1,
            minNeighbors=5,
            minSize=(60, 60),
        )

        if len(faces) > 0:
            x, y, w, h = faces[0]
            face_roi = frame[y : y + h, x : x + w]

            result = DeepFace.analyze(
                face_roi,
                actions=["emotion"],
                enforce_detection=False,
            )

            emotion = result[0]["dominant_emotion"]
            break

    capture.release()

    return emotion


def getEmotionLoop() -> list:
    face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")
   
    emotions = []
   
    capture = cv2.VideoCapture(0)

    if not capture.isOpened():
        raise Exception("Could Not Start Video Capture")

    for _ in range(0,10):
       
        ret, frame = capture.read()
       
        if not ret:
            raise Exception("Could Not Return Frame")
       

        gray_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)


        faces = face_cascade.detectMultiScale(gray_frame, scaleFactor=1.1, minNeighbors=5, minSize=(30,30))

        for (x,y,w,h) in faces:
            face_roi = frame[y:y+h, x:x+w]
            result = DeepFace.analyze(face_roi, actions = ['emotion'], enforce_detection = False)

            emotion = result[0]["dominant_emotion"]

            emotions.append(emotion)
        time.sleep(1)
    capture.release()
    return emotions

if __name__ == "__main__":
    testCap()
    print(getEmotionLoop())
