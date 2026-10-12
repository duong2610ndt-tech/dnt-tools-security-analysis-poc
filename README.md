# DNT Tools Software Security Analysis & Mock POC Server 🛡️

> **Nghiên cứu an toàn thông tin (Security Research) và xây dựng máy chủ Mock HTTP kiểm chứng điểm yếu xác thực bản quyền (License Verification) của bộ ứng dụng Desktop DNT Tools.**

---

## 🔬 Tổng Quan Nghiên Cứu

Dự án này thực hiện phân tích an toàn thông tin trên ứng dụng Desktop (`QLTK.exe`), bóc tách cơ chế xác thực bản quyền trực tuyến và chứng minh các điểm yếu logic trong kiến trúc giao tiếp Client - Server:

1. **Thiếu kiểm tra chữ ký số (No Cryptographic Verification):** Client chỉ phân tích cú pháp JSON trả về từ máy chủ mà không kiểm tra chữ ký dữ liệu (HMAC/Digital Signature), dẫn đến khả năng giả mạo phản hồi bản quyền (Spoofing).
2. **Cơ chế Fallback không an toàn:** Khi không thể kết nối tới cổng HTTPS (Port 443), client tự động fallback về giao thức HTTP không mã hóa (Port 80).
3. **Thiếu cơ chế SSL/Certificate Pinning:** Ứng dụng không ghim chứng chỉ bảo mật, cho phép bắt gói tin và điều hướng mạng nội bộ thông qua DNS file `hosts`.

---

## 💡 Giải Pháp & Kiến Trúc POC

- 🐍 **Universal Mock HTTP Server (`fake_dntshop.py`):**
  - Xây dựng server siêu nhẹ bằng thư viện chuẩn của Python (`ThreadingHTTPServer`) lắng nghe trên cổng 80.
  - Áp dụng thuật toán **Universal Catch-All Regex**: Tự động trích xuất mã nhận diện sản phẩm `TOOL{productId}-...` trong body của request và phản hồi thông tin bản quyền hợp lệ tương ứng:
    * `TOOL8`: Tool Check Info
    * `TOOL12`: Tool Check Thông Báo
    * `TOOL29`: Tool Up Cskb
    * `TOOL36`: Tool Mở Cskb
    * `TOOL34`: Tool GSM Pro
  - Giả lập đầy đủ các API: `/api/verify_license.php`, `/api/verify_export_password.php`, `/api/check_update.php`, `/api/game_data_sync.php`.
- ⚙️ **Điều Phối Hệ Thống An Toàn (DNS Orchestration & Rollback):**
  - Script PowerShell (`hosts_toggle.ps1`) tự động thêm quy tắc `127.0.0.1 dntshop.com` vào file `hosts` của Windows.
  - Quy trình vòng đời hoàn chỉnh: Kích hoạt server -> chạy tool -> dọn dẹp và khôi phục nguyên trạng file `hosts` khi đóng ứng dụng (`stop_poc.bat`), không để lại rác cấu hình mạng.

---

## 📁 Cấu Trúc Mã Nguồn

```
├── fake_dntshop.py    # Máy chủ Mock HTTP xử lý logic Catch-All và phản hồi JSON
├── hosts_toggle.ps1   # PowerShell Script điều khiển DNS file hosts an toàn
├── run_poc.ps1        # Kịch bản khởi động: Nâng quyền UAC, trỏ DNS, chạy server
├── run_poc.bat        # Batch wrapper chạy một chạm cho Windows
├── stop_poc.ps1       # Kịch bản dọn dẹp: Dừng tiến trình và rollback DNS
├── stop_poc.bat       # Batch wrapper dừng POC
├── .gitignore         # Loại trừ các file binary game và tệp log
└── README.md          # Tài liệu báo cáo phân tích bảo mật
```

---

## 🚀 Hướng Dẫn Chạy Thử Nghiệm

### Yêu cầu
- Windows 10/11 (Cần quyền Administrator để điều hướng file `hosts`).
- Python 3.8+ và Port 80 đang trống.

### Các bước thực hiện
1. **Khởi động POC:**
   Nhấp đúp vào `run_poc.bat` (chọn **Yes** khi hộp thoại UAC xuất hiện).
2. **Kiểm tra trạng thái:**
   Xem tệp `server.log` được tạo ra để quan sát các request HTTP được client gửi tới và phản hồi của server.
3. **Dọn dẹp sau thử nghiệm:**
   Nhấp đúp vào `stop_poc.bat` để dừng server và phục hồi nguyên trạng file `hosts`.

---

## ⚖️ Tuyên Bố Miễn Trừ Trách Nhiệm (Responsible Disclosure & Disclaimer)
Dự án được thực hiện nghiêm túc trên máy tính cá nhân phục vụ cho mục đích học tập, nghiên cứu an toàn thông tin và kiểm thử bảo mật nội bộ (White-hat Security Research). Tác giả không cung cấp bất kỳ tệp nhị phân trò chơi hoặc phần mềm của bên thứ ba nào trong kho lưu trữ này.