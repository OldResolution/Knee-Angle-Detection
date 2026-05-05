const https = require('https');

const API_KEY = 'AIzaSyDcQxqLclf2iMmc1-JYFT_DdXs9sw-v834';

function register() {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      email: 'test@example.com',
      password: 'password123',
      returnSecureToken: true
    });

    const req = https.request({
      hostname: 'identitytoolkit.googleapis.com',
      path: '/v1/accounts:signUp?key=' + API_KEY,
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

register().then(r => console.log(r)).catch(console.error);
