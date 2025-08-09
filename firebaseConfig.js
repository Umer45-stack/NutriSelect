const admin = require('firebase-admin');
const serviceAccount = require('./config/instagram-clone-b1843-firebase-adminsdk-osujo-9092833819.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  // Optionally add your databaseURL if needed:
  // databaseURL: "https://<your-project-id>.firebaseio.com"
});

module.exports = admin;
