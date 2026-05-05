const https = require('https');

const API_KEY = 'AIzaSyDcQxqLclf2iMmc1-JYFT_DdXs9sw-v834';
const PROJECT_ID = 'gopalproject-77869';

function login() {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      email: 'test@example.com',
      password: 'password123',
      returnSecureToken: true
    });

    const req = https.request({
      hostname: 'identitytoolkit.googleapis.com',
      path: '/v1/accounts:signInWithPassword?key=' + API_KEY,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
      }
    }, res => {
      let body = '';
      res.on('data', d => body += d);
      res.on('end', () => {
        try {
          resolve(JSON.parse(body));
        } catch(e) { reject(e); }
      });
    });

    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

function writeDocument(token, collectionId, documentId, fields) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({ fields });
    const req = https.request({
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collectionId}/${documentId}`,
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': data.length
      }
    }, res => {
      let body = '';
      res.on('data', d => body += d);
      res.on('end', () => resolve(JSON.parse(body)));
    });

    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

async function run() {
  const auth = await login();
  console.log("Logged in UID:", auth.localId);
  
  const res = await writeDocument(auth.idToken, `users/${auth.localId}/sessions`, 'test_session_123', {
    test: { stringValue: 'It works!' }
  });
  console.log("Write Result:", JSON.stringify(res, null, 2));
}

run().catch(console.error);
