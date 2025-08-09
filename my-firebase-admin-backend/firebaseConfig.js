const admin = require('firebase-admin');
// Update the path below to the location of your service account key file.
// For example, if your file is in a folder named "config" in your project:
// const serviceAccount = require('./config/instagram-clone-b1843-firebase-adminsdk-osujo-9092833819.json');
const serviceAccount = require('./config/instagram-clone-b1843-firebase-adminsdk-osujo-9092833819.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  // Optionally add your databaseURL if needed:
  // databaseURL: "https://<your-project-id>.firebaseio.com"
});

module.exports = admin;
