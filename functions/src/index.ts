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

function pickLang(value: unknown): SupportedLang {
  if (value === "ko" || value === "en" || value === "lo") return value;
  return "ko";
}

/**
 * Triggered whenever a new message document is created under
 * chats/{chatId}/messages/{messageId}.
 * Looks up the other participant in the chat, fetches their FCM token
 * and preferred language, and sends a push notification.
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
    const participants = (chatData.participants as string[] | undefined) ?? [];
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
      logger.info("Recipient has no FCM token, skipping push", {recipientId});
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
        data: {
          chatId,
          type: "chat_message",
        },
      });
      logger.info("Push sent", {recipientId, chatId});
    } catch (err) {
      logger.error("Failed to send push", {recipientId, chatId, error: String(err)});
    }
  }
);
