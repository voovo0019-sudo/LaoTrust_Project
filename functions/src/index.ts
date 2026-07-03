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

const NEW_REQUEST_TITLE: Record<SupportedLang, string> = {
  ko: "새 서비스 요청",
  en: "New service request",
  lo: "ມີຄຳຮ້ອງໃໝ່",
};

const NEW_REQUEST_BODY: Record<SupportedLang, string> = {
  ko: "내 카테고리에 새 요청이 들어왔습니다. 확인해보세요!",
  en: "A new request has arrived in your category. Check it out!",
  lo: "ມີຄຳຮ້ອງໃໝ່ໃນໝວດໝູ່ຂອງທ່ານ. ກວດເບິ່ງເລີຍ!",
};

const NEW_QUOTE_TITLE: Record<SupportedLang, string> = {
  ko: "견적이 도착했습니다",
  en: "New quote received",
  lo: "ໄດ້ຮັບໃບສະເໜີລາຄາໃໝ່",
};

const NEW_QUOTE_BODY: Record<SupportedLang, string> = {
  ko: "전문가가 견적을 보냈습니다. 확인해보세요!",
  en: "An expert sent you a quote. Check it out!",
  lo: "ຜູ້ຊ່ຽວຊານສົ່ງໃບສະເໜີລາຄາໃຫ້ທ່ານ. ກວດເບິ່ງເລີຍ!",
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

/**
 * Sends push notifications to all experts in the matching category
 * when a new service request document is created.
 */
export const onNewRequest = onDocumentCreated(
  "artifacts/{appId}/public/data/requests/{requestId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.warn("No data associated with the event");
      return;
    }

    const request = snap.data();
    const requestId = event.params.requestId;
    const categoryKey = request.categoryKey as string | undefined;
    const clientId = request.userId as string | undefined;

    if (!categoryKey) {
      logger.warn("Request has no categoryKey, skipping", {requestId});
      return;
    }

    // 같은 카테고리 등록 전문가 조회
    // users 컬렉션에서 userType=expert AND categories 배열에 categoryKey 포함
    const expertsSnap = await db
      .collection("users")
      .where("userType", "==", "expert")
      .where("categories", "array-contains", categoryKey)
      .get();

    if (expertsSnap.empty) {
      logger.info("No experts found for category", {categoryKey});
      return;
    }

    // 본인(손님) 제외 + 토큰 있는 전문가만 수집
    const tokens: string[] = [];
    const tokenLangMap: Record<string, string> = {};

    for (const doc of expertsSnap.docs) {
      if (doc.id === clientId) continue;
      const data = doc.data();
      const token = data.fcmToken as string | undefined;
      if (!token) continue;
      tokens.push(token);
      tokenLangMap[token] = pickLang(data.preferredLang);
    }

    if (tokens.length === 0) {
      logger.info("No expert tokens found", {categoryKey});
      return;
    }

    // 언어별로 묶어서 멀티캐스트 발송 (최대 500개/호출)
    const langGroups: Record<SupportedLang, string[]> = {
      ko: [],
      en: [],
      lo: [],
    };
    for (const token of tokens) {
      const lang = (tokenLangMap[token] ?? "ko") as SupportedLang;
      langGroups[lang].push(token);
    }

    const langs: SupportedLang[] = ["ko", "en", "lo"];
    for (const lang of langs) {
      const group = langGroups[lang];
      if (group.length === 0) continue;

      // 500개 단위로 청킹
      for (let i = 0; i < group.length; i += 500) {
        const chunk = group.slice(i, i + 500);
        try {
          const result = await messaging.sendEachForMulticast({
            tokens: chunk,
            notification: {
              title: NEW_REQUEST_TITLE[lang],
              body: NEW_REQUEST_BODY[lang],
            },
            data: {
              requestId,
              categoryKey,
              type: "new_request",
            },
          });
          logger.info("Request push sent", {
            lang,
            successCount: result.successCount,
            failureCount: result.failureCount,
            categoryKey,
          });
        } catch (err) {
          logger.error("Failed to send request push", {
            lang,
            categoryKey,
            error: String(err),
          });
        }
      }
    }
  }
);

/**
 * Sends a push notification to the client when an expert
 * submits a new quote for their service request.
 */
export const onNewQuote = onDocumentCreated(
  "quotes/{quoteId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.warn("No data associated with the event");
      return;
    }

    const quote = snap.data();
    const quoteId = event.params.quoteId;
    const clientId = quote.clientId as string | undefined;
    const requestId = quote.requestId as string | undefined;
    const expertId = quote.expertId as string | undefined;

    if (!clientId) {
      logger.warn("Quote has no clientId, skipping", {quoteId});
      return;
    }

    const userDoc = await db.collection("users").doc(clientId).get();
    if (!userDoc.exists) {
      logger.warn("Client user document not found", {clientId});
      return;
    }

    const userData = userDoc.data() || {};
    const token = userData.fcmToken as string | undefined;
    if (!token) {
      logger.info("Client has no FCM token, skipping push", {clientId});
      return;
    }

    const lang = pickLang(userData.preferredLang);

    try {
      await messaging.send({
        token,
        notification: {
          title: NEW_QUOTE_TITLE[lang],
          body: NEW_QUOTE_BODY[lang],
        },
        data: {
          quoteId,
          requestId: requestId ?? "",
          expertId: expertId ?? "",
          type: "new_quote",
        },
      });
      logger.info("Quote push sent", {clientId, quoteId});
    } catch (err) {
      logger.error("Failed to send quote push", {
        clientId,
        quoteId,
        error: String(err),
      });
    }
  }
);
