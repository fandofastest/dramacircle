export const memberUiHtml = `<!doctype html>
<html lang="id">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Member & VIP</title>
  <style>
    body{font-family:Arial,sans-serif;max-width:720px;margin:24px auto;padding:0 12px}
    input,button{padding:8px;margin:4px 0;width:100%}
    .card{border:1px solid #ddd;border-radius:8px;padding:12px;margin:12px 0}
    pre{background:#111;color:#f3f3f3;padding:10px;border-radius:6px;overflow:auto}
    .row{display:flex;gap:8px}
    .row button{width:auto}
  </style>
</head>
<body>
  <h2>Member Login/Register + VIP Toggle</h2>
  <div class="card">
    <h3>Register</h3>
    <input id="regName" placeholder="Nama" />
    <input id="regEmail" placeholder="Email" />
    <input id="regPassword" placeholder="Password" type="password" />
    <button onclick="register()">Register</button>
  </div>
  <div class="card">
    <h3>Login</h3>
    <input id="loginEmail" placeholder="Email" />
    <input id="loginPassword" placeholder="Password" type="password" />
    <button onclick="login()">Login</button>
  </div>
  <div class="card">
    <h3>Status Member</h3>
    <div class="row">
      <button onclick="me()">Refresh Profile</button>
      <button onclick="setVip(true)">Ubah ke VIP</button>
      <button onclick="setVip(false)">Ubah ke Reguler</button>
    </div>
  </div>
  <div class="card">
    <h3>VIP Content</h3>
    <button onclick="vipContent()">Ambil Data VIP</button>
  </div>
  <pre id="out">Siap.</pre>
  <script>
    const out = document.getElementById("out");
    const tokenKey = "member_token";
    const setOut = (v) => out.textContent = typeof v === "string" ? v : JSON.stringify(v, null, 2);
    const token = () => localStorage.getItem(tokenKey) || "";
    const headers = () => ({ "Content-Type": "application/json", ...(token() ? { Authorization: "Bearer " + token() } : {}) });
    async function call(path, method="GET", body){
      const res = await fetch(path,{ method, headers: headers(), body: body ? JSON.stringify(body) : undefined });
      const data = await res.json();
      if(!res.ok){ throw new Error(JSON.stringify(data)); }
      return data;
    }
    async function register(){
      try{
        const data = await call("/api/member/register","POST",{
          name: document.getElementById("regName").value,
          email: document.getElementById("regEmail").value,
          password: document.getElementById("regPassword").value
        });
        localStorage.setItem(tokenKey, data.data.token);
        setOut(data);
      }catch(e){ setOut(String(e)); }
    }
    async function login(){
      try{
        const data = await call("/api/member/login","POST",{
          email: document.getElementById("loginEmail").value,
          password: document.getElementById("loginPassword").value
        });
        localStorage.setItem(tokenKey, data.data.token);
        setOut(data);
      }catch(e){ setOut(String(e)); }
    }
    async function me(){ try{ setOut(await call("/api/member/me")); }catch(e){ setOut(String(e)); } }
    async function setVip(isVip){ try{ setOut(await call("/api/member/vip","PATCH",{isVip})); }catch(e){ setOut(String(e)); } }
    async function vipContent(){ try{ setOut(await call("/api/member/vip/content")); }catch(e){ setOut(String(e)); } }
  </script>
</body>
</html>`;
