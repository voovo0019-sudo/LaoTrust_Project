import {setGlobalOptions} from "firebase-functions";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

initializeApp();
setGlobalOptions({maxInstances: 10});

const db = getFirestore();
const messaging = getMessaging();

type SupportedLang = "ko" | "en" | "lo";

const NEW_MESSAGE_TITLE: Record<SupportedLang, string> = {
  ko: "새 메시지",
  en: "New message",
  lo: "ຂໍ້ຄວາມໃໝ່",
};

const NEW_APPLICATION_TITLE: Record<SupportedLang, string> = {
  ko: "새 지원자",
  en: "New applicant",
  lo: "ຜູ້ສະໝັກໃໝ່",
};

const NEW_APPLICATION_BODY: Record<SupportedLang, string> = {
  ko: "내 공고에 지원자가 생겼습니다. 확인해보세요!",
  en: "Someone applied to your job posting. Check it out!",
  lo: "ມີຜູ້ສະໝັກວຽກຂອງທ່ານ. ກວດເບິ່ງເລີຍ!",
};

/**
 * Normalizes an arbitrary value into one of the supported language codes,
 * defaulting to Korean when the value is missing or unrecognized.
 * @param {unknown} value Raw preferred language value from Firestore.
 * @return {SupportedLang} Normalized language code.
 */
function pickLang(value: unknown): SupportedLang {
  if (value === "ko" || value === "en" || value === "lo") return value;
  return "ko";
}

/**
 * Sends a push notification to the other chat participant when a new
 * message document is created.
 */
export const onNewChatMessage = onDocumentCreated(
  "chats/{chatId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.warn("No data associated with the event");
      return;
    }
    const message = snap.data();
    const chatId = event.params.chatId;
    const senderId = message.senderId as string | undefined;
    const text = (message.text as string | undefined) ?? "";

    if (!senderId) {
      logger.warn("Message has no senderId, skipping", {chatId});
      return;
    }

    const chatDoc = await db.collection("chats").doc(chatId).get();
    if (!chatDoc.exists) {
      logger.warn("Chat document not found", {chatId});
      return;
    }

    const chatData = chatDoc.data() || {};
    const participants =
      (chatData.participants as string[] | undefined) ?? [];
    const recipientId = participants.find((uid) => uid !== senderId);

    if (!recipientId) {
      logger.warn("No recipient found for chat", {chatId});
      return;
    }

    const userDoc = await db.collection("users").doc(recipientId).get();
    if (!userDoc.exists) {
      logger.warn("Recipient user document not found", {recipientId});
      return;
    }

    const userData = userDoc.data() || {};
    const token = userData.fcmToken as string | undefined;
    if (!token) {
      logger.info("Recipient has no FCM token, skipping push",
        {recipientId});
      return;
    }

    const lang = pickLang(userData.preferredLang);

    try {
      await messaging.send({
        token,
        notification: {
          title: NEW_MESSAGE_TITLE[lang],
          body: text.length > 80 ? `${text.substring(0, 80)}...` : text,
        },
        data: {chatId, type: "chat_message"},
      });
      logger.info("Push sent", {recipientId, chatId});
    } catch (err) {
      logger.error("Failed to send push", {
        recipientId,
        chatId,
        error: String(err),
      });
    }
  }
);

/**
 * Sends a push notification to the employer when a new
 * application document is created in the applications collection.
 */
export const onNewApplication = onDocumentCreated(
  "applications/{applicationId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.warn("No data associated with the event");
      return;
    }

    const application = snap.data();
    const applicationId = event.params.applicationId;
    const employerId = application.employerId as string | undefined;
    const jobId = application.jobId as string | undefined;

    if (!employerId) {
      logger.warn("Application has no employerId, skipping",
        {applicationId});
      return;
    }

    const userDoc = await db.collection("users").doc(employerId).get();
    if (!userDoc.exists) {
      logger.warn("Employer user document not found", {employerId});
      return;
    }

    const userData = userDoc.data() || {};
    const token = userData.fcmToken as string | undefined;
    if (!token) {
      logger.info("Employer has no FCM token, skipping push", {employerId});
      return;
    }

    const lang = pickLang(userData.preferredLang);

    try {
      await messaging.send({
        token,
        notification: {
          title: NEW_APPLICATION_TITLE[lang],
          body: NEW_APPLICATION_BODY[lang],
        },
        data: {
          jobId: jobId ?? "",
          applicationId,
          type: "new_application",
        },
      });
      logger.info("Application push sent", {employerId, applicationId});
    } catch (err) {
      logger.error("Failed to send application push", {
        employerId,
        applicationId,
        error: String(err),
      });
    }
  }
);
