/* eslint-disable max-len */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * Sets a custom claim on a user to mark them as an admin.
 * @param {object} data The data passed to the function, expecting `data.email`.
 * @param {object} context The context of the function call.
 * @returns {Promise<object>} A promise that resolves with error.
 */
exports.addAdminRole = functions.https.onCall((data, context) => {
  if (context.auth.token.admin !== true) {
    return {error: "Request not authorized. User must be an admin."};
  }
  return admin.auth().getUserByEmail(data.email).then((user) => {
    return admin.auth().setCustomUserClaims(user.uid, {admin: true});
  }).then(() => {
    return {message: `Success! ${data.email} has been made an admin.`};
  }).catch((err) => {
    return {error: err.message};
  });
});

/**
 * Disables a user's account in Firebase Authentication.
 * @param {object} data The data passed, expecting `data.uid`.
 * @param {object} context The context of the call.
 * @returns {Promise<object>} A promise that resolves with a success message.
 */
exports.suspendUser = functions.https.onCall(async (data, context) => {
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
        "permission-denied", "Only admins can suspend users.",
    );
  }
  const uid = data.uid;
  await admin.auth().updateUser(uid, {disabled: true});
  return {message: "User has been successfully suspended."};
});


/**
 * Processes a payout for a delivered order.
 * @param {object} data The data passed, expecting `data.orderId`.
 * @param {object} context The context of the call.
 * @returns {Promise<object>} A promise that resolves with a success message.
 */
exports.processPayout = functions.https.onCall(async (data, context) => {
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
        "permission-denied", "Only admins can process payouts.",
    );
  }

  const orderId = data.orderId;
  const firestore = admin.firestore();
  const orderRef = firestore.collection("orders").doc(orderId);
  const orderDoc = await orderRef.get();

  if (!orderDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Order not found.");
  }
  const orderData = orderDoc.data();

  if (orderData.orderStatus !== "delivered") {
    throw new functions.https.HttpsError(
        "failed-precondition", "Order must be delivered to process payout.",
    );
  }
  if (orderData.paymentStatus === "paid") {
    throw new functions.https.HttpsError(
        "failed-precondition", "This order has already been paid out.",
    );
  }

  const farmerId = orderData.farmerUid;
  const farmerWalletRef = firestore.collection("wallets").doc(farmerId);
  const totalPrice = orderData.totalPrice;
  const commission = totalPrice * 0.05; // 5% platform commission
  const farmerPayout = totalPrice - commission;

  return firestore.runTransaction(async (transaction) => {
    const farmerWalletDoc = await transaction.get(farmerWalletRef);
    if (!farmerWalletDoc.exists) {
      transaction.set(farmerWalletRef, {balance: farmerPayout});
    } else {
      const newBalance = (farmerWalletDoc.data().balance || 0) + farmerPayout;
      transaction.update(farmerWalletRef, {balance: newBalance});
    }

    const transactionRef = firestore.collection("transactions").doc();
    transaction.set(transactionRef, {
      uid: farmerId,
      amount: farmerPayout,
      type: "payout",
      orderId: orderId,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    transaction.update(orderRef, {paymentStatus: "paid"});
  }).then(() => {
    return {message: "Payout processed successfully!"};
  });
});

// ==> NEW FUNCTION TO SUSPEND A USER <==
exports.suspendUser = functions.https.onCall(async (data, context) => {
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
        "permission-denied", "Only admins can suspend users.",
    );
  }
  const uid = data.uid;
  await admin.auth().updateUser(uid, {disabled: true});
  // Also update the status in Firestore for easy UI updates
  await admin.firestore().collection("users").doc(uid).update({status: "suspended"});
  return {message: "User has been successfully suspended."};
});

// ==> NEW FUNCTION TO REINSTATE A USER <==
exports.reinstateUser = functions.https.onCall(async (data, context) => {
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
        "permission-denied", "Only admins can reinstate users.",
    );
  }
  const uid = data.uid;
  await admin.auth().updateUser(uid, {disabled: false});
  await admin.firestore().collection("users").doc(uid).update({status: "active"});
  return {message: "User has been successfully reinstated."};
});
