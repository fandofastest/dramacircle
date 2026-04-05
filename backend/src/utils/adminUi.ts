export const adminUiHtml = `<!doctype html>
<html lang="id">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Admin Panel</title>
  <style>
    *{box-sizing:border-box} body{margin:0;font-family:Inter,Segoe UI,Arial,sans-serif;background:#0b1020;color:#e6ebff}
    .wrap{max-width:1100px;margin:24px auto;padding:0 16px}
    .head{display:flex;justify-content:space-between;align-items:center;margin-bottom:16px}
    .badge{padding:6px 10px;border-radius:999px;background:#1f2a4d;color:#98a8ff;font-size:12px}
    .grid{display:grid;grid-template-columns:1fr;gap:16px}
    .card{background:linear-gradient(145deg,#121a33,#0f1730);border:1px solid #243158;border-radius:14px;padding:16px;box-shadow:0 10px 25px rgba(0,0,0,.25)}
    .title{font-size:18px;margin:0 0 12px 0}
    .row{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px}
    .row3{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:10px}
    input,select,button{width:100%;padding:10px 12px;border-radius:10px;border:1px solid #2f3b66;background:#0f1730;color:#f6f8ff}
    input::placeholder{color:#8fa0d9}
    button{cursor:pointer;background:#4d6bff;border-color:#4d6bff;font-weight:600}
    button.sec{background:#243158;border-color:#3a4a7e}
    button.warn{background:#f26d6d;border-color:#f26d6d}
    table{width:100%;border-collapse:collapse;margin-top:12px}
    th,td{text-align:left;padding:10px;border-bottom:1px solid #27345c;font-size:14px;vertical-align:top}
    .muted{color:#93a2d3;font-size:12px}
    .hidden{display:none}
    .modal-backdrop{position:fixed;inset:0;background:rgba(4,8,20,.75);display:none;align-items:center;justify-content:center;padding:16px;z-index:99}
    .modal{width:min(520px,100%);background:linear-gradient(145deg,#121a33,#0f1730);border:1px solid #2a3866;border-radius:14px;padding:16px}
    .modal h3{margin:0 0 10px 0}
    .modal .actions{display:flex;gap:8px;justify-content:flex-end;margin-top:12px}
    .modal .actions button{width:auto;min-width:110px}
    .notice{margin-top:10px;padding:10px;border-radius:10px;background:#1e2a4a;border:1px solid #304275;color:#d9e3ff}
    .notice.err{background:#4a2020;border-color:#7a3535;color:#ffd6d6}
    @media (max-width:800px){.row,.row3{grid-template-columns:1fr}}
  </style>
</head>
<body>
  <div class="wrap">
    <div class="head">
      <h1 style="margin:0">Admin Panel</h1>
      <span class="badge" id="authState">Belum login</span>
    </div>
    <div id="loginCard" class="card">
      <h2 class="title">Login Admin</h2>
      <div class="row">
        <input id="username" placeholder="Admin username" />
        <input id="password" placeholder="Admin password" type="password" />
      </div>
      <div style="margin-top:10px">
        <button onclick="loginAdmin()">Login</button>
      </div>
    </div>
    <div id="panel" class="grid hidden">
      <div class="card">
        <div style="display:flex;justify-content:space-between;align-items:center;gap:10px">
          <h2 class="title" style="margin:0">List User</h2>
          <div style="display:flex;gap:8px">
            <button onclick="openCreateModal()">Tambah User</button>
            <button class="sec" onclick="loadUsers()">Refresh</button>
            <button class="warn" onclick="logoutAdmin()">Logout</button>
          </div>
        </div>
        <table>
          <thead>
            <tr><th>Nama</th><th>Email</th><th>Status</th><th>Aksi</th></tr>
          </thead>
          <tbody id="usersBody"></tbody>
        </table>
        <p class="muted">Tersedia aksi cepat: toggle VIP/Reguler, edit nama+password, dan hapus user.</p>
        <div id="notice" class="notice hidden"></div>
      </div>
    </div>
  </div>
  <div id="editModalBackdrop" class="modal-backdrop">
    <div class="modal">
      <h3>Edit User</h3>
      <div class="row">
        <input id="editName" placeholder="Nama baru" />
        <input id="editPassword" placeholder="Password baru (optional)" type="password" />
      </div>
      <div class="actions">
        <button class="sec" onclick="closeEditModal()">Batal</button>
        <button onclick="submitEditModal()">Simpan</button>
      </div>
    </div>
  </div>
  <div id="createModalBackdrop" class="modal-backdrop">
    <div class="modal">
      <h3>Tambah User</h3>
      <div class="row3">
        <input id="createName" placeholder="Nama" />
        <input id="createEmail" placeholder="Email" />
        <input id="createPassword" placeholder="Password" type="password" />
      </div>
      <div class="row" style="margin-top:10px">
        <select id="createVip">
          <option value="false">Reguler</option>
          <option value="true">VIP</option>
        </select>
        <div></div>
      </div>
      <div class="actions">
        <button class="sec" onclick="closeCreateModal()">Batal</button>
        <button onclick="createUser()">Simpan User</button>
      </div>
    </div>
  </div>
  <div id="confirmModalBackdrop" class="modal-backdrop">
    <div class="modal">
      <h3 id="confirmTitle">Konfirmasi</h3>
      <p id="confirmMessage" class="muted" style="margin:0"></p>
      <div class="actions">
        <button class="sec" onclick="closeConfirmModal()">Batal</button>
        <button id="confirmOkBtn" class="warn">Lanjut</button>
      </div>
    </div>
  </div>
  <script>
    const tokenKey='admin_token';
    const getToken=()=>localStorage.getItem(tokenKey)||'';
    const setAuth=(loggedIn)=>{document.getElementById('authState').textContent=loggedIn?'Admin login':'Belum login';document.getElementById('loginCard').classList.toggle('hidden',loggedIn);document.getElementById('panel').classList.toggle('hidden',!loggedIn);}
    const noticeEl=document.getElementById('notice');
    const editModal=document.getElementById('editModalBackdrop');
    const createModal=document.getElementById('createModalBackdrop');
    const confirmModal=document.getElementById('confirmModalBackdrop');
    let editState={id:'',name:''};
    const authHeaders=()=>({'Content-Type':'application/json',...(getToken()?{Authorization:'Bearer '+getToken()}: {})});
    function showNotice(message,isError=false){
      noticeEl.textContent=message;
      noticeEl.classList.remove('hidden');
      noticeEl.classList.toggle('err',isError);
      clearTimeout(window.__noticeTimer);
      window.__noticeTimer=setTimeout(()=>noticeEl.classList.add('hidden'),2500);
    }
    async function api(path,method='GET',body){
      const res=await fetch(path,{method,headers:authHeaders(),body:body?JSON.stringify(body):undefined});
      const data=await res.json().catch(()=>({}));
      if(!res.ok){throw new Error(data.message||JSON.stringify(data));}
      return data;
    }
    async function loginAdmin(){
      try{
        const data=await api('/api/admin/login','POST',{username:document.getElementById('username').value,password:document.getElementById('password').value});
        localStorage.setItem(tokenKey,data.data.token); setAuth(true); loadUsers();
        showNotice('Login berhasil');
      }catch(e){showNotice(String(e),true);}
    }
    function logoutAdmin(){localStorage.removeItem(tokenKey);setAuth(false);showNotice('Logout berhasil');}
    async function loadUsers(){
      try{
        const data=await api('/api/admin/members');
        const body=document.getElementById('usersBody'); body.innerHTML='';
        for(const user of data.data){
          const tr=document.createElement('tr');
          tr.innerHTML='<td>'+escapeHtml(user.name)+'</td><td>'+escapeHtml(user.email)+'</td><td>'+(user.isVip?'VIP':'Reguler')+'</td><td><button class="sec" onclick="toggleVip(\\''+user.id+'\\','+user.isVip+')">'+(user.isVip?'Jadikan Reguler':'Jadikan VIP')+'</button> <button class="sec" onclick="editNamePassword(\\''+user.id+'\\',\\''+escapeJs(user.name)+'\\')">Edit Nama/Password</button> <button class="warn" onclick="deleteUser(\\''+user.id+'\\')">Hapus</button></td>';
          body.appendChild(tr);
        }
      }catch(e){showNotice(String(e),true);}
    }
    async function createUser(){
      try{
        await api('/api/admin/members','POST',{
          name:document.getElementById('createName').value,
          email:document.getElementById('createEmail').value,
          password:document.getElementById('createPassword').value,
          isVip:document.getElementById('createVip').value==='true'
        });
        document.getElementById('createName').value='';document.getElementById('createEmail').value='';document.getElementById('createPassword').value='';document.getElementById('createVip').value='false';
        closeCreateModal();
        loadUsers();
        showNotice('User berhasil dibuat');
      }catch(e){showNotice(String(e),true);}
    }
    function openCreateModal(){
      document.getElementById('createName').value='';
      document.getElementById('createEmail').value='';
      document.getElementById('createPassword').value='';
      document.getElementById('createVip').value='false';
      createModal.style.display='flex';
    }
    function closeCreateModal(){
      createModal.style.display='none';
    }
    async function toggleVip(id,currentVip){
      try{
        await api('/api/admin/members/'+id,'PATCH',{isVip:!currentVip});
        loadUsers();
        showNotice('Status VIP berhasil diubah');
      }catch(e){showNotice(String(e),true);}
    }
    async function editNamePassword(id,name){
      editState={id,name};
      document.getElementById('editName').value=name;
      document.getElementById('editPassword').value='';
      editModal.style.display='flex';
    }
    async function submitEditModal(){
      const newName=document.getElementById('editName').value;
      const newPassword=document.getElementById('editPassword').value;
      try{
        const payload={name:newName};
        if(newPassword&&newPassword.trim().length>0){payload.password=newPassword;}
        await api('/api/admin/members/'+editState.id,'PATCH',payload);
        closeEditModal();
        loadUsers();
        showNotice('User berhasil diupdate');
      }catch(e){showNotice(String(e),true);}
    }
    function closeEditModal(){
      editModal.style.display='none';
    }
    async function deleteUser(id){
      openConfirmModal('Hapus user?','Aksi ini tidak bisa dibatalkan.',async()=>{
        try{
          await api('/api/admin/members/'+id,'DELETE');
          loadUsers();
          showNotice('User berhasil dihapus');
        }catch(e){showNotice(String(e),true);}
      });
    }
    function openConfirmModal(title,message,onOk){
      document.getElementById('confirmTitle').textContent=title;
      document.getElementById('confirmMessage').textContent=message;
      const btn=document.getElementById('confirmOkBtn');
      btn.onclick=async()=>{closeConfirmModal(); await onOk();};
      confirmModal.style.display='flex';
    }
    function closeConfirmModal(){
      confirmModal.style.display='none';
    }
    function escapeHtml(v){return String(v).replace(/[&<>"']/g,(m)=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[m]));}
    function escapeJs(v){return String(v).replace(/['\\\\]/g,'\\\\$&');}
    setAuth(!!getToken()); if(getToken()){loadUsers();}
  </script>
</body>
</html>`;
