const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// 🔥 채팅 알림
exports.sendChatNotification = functions.firestore
  .document('chats/{chatId}/messages/{messageId}')
  .onCreate(async (snap, context) => {

    const newMessage = snap.data();
    const chatId = context.params.chatId;
    const senderId = newMessage.senderId;

    // 채팅 문서 확인 → 상대 UID 찾기
    const chatDoc = await admin.firestore().collection('chats').doc(chatId).get();
    const users = chatDoc.data().users;
    const receiverId = users.find(uid => uid !== senderId);

    // 상대 토큰 가져오기
    const receiverDoc = await admin.firestore().collection("users").doc(receiverId).get();
    const token = receiverDoc.data().fcmToken;

    if (!token) return;

    // 알림 payload
    const payload = {
      notification: {
        title: "새 메시지 도착!",
        body: newMessage.text,
      },
      token: token,
    };

    // 전송
    return admin.messaging().send(payload);
  });

// 🔥 매칭 알림
exports.sendMatchNotification = functions.firestore
  .document('matches/{matchId}')
  .onCreate(async (snap, context) => {

    const match = snap.data();
    const userA = match.userA;
    const userB = match.userB;

    const userDocA = await admin.firestore().collection("users").doc(userA).get();
    const tokenA = userDocA.data().fcmToken;

    const userDocB = await admin.firestore().collection("users").doc(userB).get();
    const tokenB = userDocB.data().fcmToken;

    const payload = {
      notification: {
        title: "매칭 성공 🎉",
        body: "상대도 좋아요를 눌렀어요!",
      }
    };

    const promises = [];

    if (tokenA) promises.push(admin.messaging().send({ ...payload, token: tokenA }));
    if (tokenB) promises.push(admin.messaging().send({ ...payload, token: tokenB }));

    return Promise.all(promises); // 🔥 필수
  });
