const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// This is a callable function.
// It takes a user's email and gives them an "admin" custom claim.
exports.addAdminRole = functions.https.onCall((data, context) => {
  // Check if the user making the request is already an admin.
  // This is a crucial security step for a real application.
  if (context.auth.token.admin !== true) {
    return {error: "Only admins can add other admins."};
  }

  // Get the user and add the custom claim.
  return admin
      .auth()
      .getUserByEmail(data.email)
      .then((user) => {
        return admin.auth().setCustomUserClaims(user.uid, {
          admin: true,
        });
      })
      .then(() => {
        return {message: `Success! ${data.email} has been made an admin.`};
      })
      .catch((err) => {
        return err;
      });
});

// Add this new function to your index.js file
exports.processPayout = functions.https.onCall(async (data, context) => {
  // Ensure the caller is an admin
  if (context.auth.token.admin !== true) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can process payouts.",
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

  // Check conditions for payout
  if (orderData.orderStatus !== "delivered") {
    throw new functions.https.HttpsError(
        "failed-precondition",
        "Order must be delivered to process payout.",
    );
  }
  if (orderData.paymentStatus === "paid") {
    throw new functions.https.HttpsError(
        "failed-precondition",
        "This order has already been paid out.",
    );
  }

  const farmerId = orderData.farmerUid;
  const farmerWalletRef = firestore.collection("wallets").doc(farmerId);
  const totalPrice = orderData.totalPrice;

  // Assume a 5% platform commission
  const commission = totalPrice * 0.05;
  const farmerPayout = totalPrice - commission;

  // Use a transaction to ensure atomicity
  return firestore
      .runTransaction(async (transaction) => {
        const farmerWalletDoc = await transaction.get(farmerWalletRef);

        if (!farmerWalletDoc.exists) {
        // Create wallet if it doesn't exist
          transaction.set(farmerWalletRef, {balance: farmerPayout});
        } else {
          const newBalance = (farmerWalletDoc.data().balance || 0)+farmerPayout;
          transaction.update(farmerWalletRef, {balance: newBalance});
        }

        // Create a transaction record
        const transactionRef = firestore.collection("transactions").doc();
        transaction.set(transactionRef, {
          uid: farmerId,
          amount: farmerPayout,
          type: "payout",
          orderId: orderId,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Update the order status
        transaction.update(orderRef, {paymentStatus: "paid"});
      })
      .then(() => {
        return {message: "Payout processed successfully!"};
      });
});
