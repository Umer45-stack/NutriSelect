const express = require('express');
const admin = require('./firebaseConfig'); // Ensure firebaseConfig.js is in the same directory
const app = express();
const port = process.env.PORT || 3000;

// Middleware to parse JSON bodies
app.use(express.json());

// Endpoint to set the admin custom claim for a given user
app.post('/setAdminClaim', async (req, res) => {
  const { uid } = req.body;
  
  // Check if uid is provided
  if (!uid) {
    return res.status(400).json({ error: 'Missing uid parameter.' });
  }
  
  try {
    // Set the custom claim { admin: true } for the user with the provided uid
    await admin.auth().setCustomUserClaims(uid, { admin: true });
    res.status(200).json({ message: `Admin claim set successfully for UID: ${uid}` });
  } catch (error) {
    console.error('Error setting admin claim:', error);
    res.status(500).json({ error: error.message });
  }
});

// Start the server
app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
