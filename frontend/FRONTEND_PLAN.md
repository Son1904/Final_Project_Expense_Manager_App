# 📱 FRONTEND DEVELOPMENT PLAN

## 🎯 Mục tiêu
Xây dựng ứng dụng di động Flutter để quản lý chi tiêu cá nhân, kết nối với Backend API đã hoàn thành.

---

## 📋 Danh sách công việc

### **PHASE 1: Setup & Architecture (2-3 giờ)** ✅

#### 1.1 Project Setup
- ✅ Tạo Flutter project (đã xong)
- ✅ Cài đặt dependencies cần thiết
- ✅ Cấu hình project structure theo Clean Architecture
- ✅ Setup theme (colors, text styles)

#### 1.2 Dependencies cần cài đặt
```yaml
dependencies:
  # State Management
  provider: ^6.1.1
  
  # HTTP & API
  http: ^1.1.0
  dio: ^5.4.0
  
  # Local Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  
  # UI Components
  flutter_svg: ^2.0.9
  google_fonts: ^6.1.0
  intl: ^0.19.0
  
  # Charts & Graphs
  fl_chart: ^0.65.0
  
  # Utils
  logger: ^2.0.2
```

#### 1.3 Folder Structure
```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_strings.dart
│   │   └── api_constants.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── utils/
│       ├── validators.dart
│       └── formatters.dart
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── transaction_model.dart
│   │   └── category_model.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   ├── transaction_service.dart
│   │   └── storage_service.dart
│   └── repositories/
│       ├── auth_repository.dart
│       └── transaction_repository.dart
├── presentation/
│   ├── screens/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── transactions/
│   │   └── profile/
│   ├── widgets/
│   │   ├── common/
│   │   └── transaction/
│   └── providers/
│       ├── auth_provider.dart
│       └── transaction_provider.dart
└── main.dart
```

---

### **PHASE 2: Core Services (3-4 giờ)**

#### 2.1 API Service
- ⬜ Setup Dio HTTP client
- ⬜ Add interceptors (auth token, logging)
- ⬜ Error handling
- ⬜ Base URL configuration

#### 2.2 Storage Service
- ⬜ SharedPreferences wrapper
- ⬜ Secure storage cho tokens
- ⬜ Save/get access token
- ⬜ Save/get refresh token

#### 2.3 Models
- ⬜ User Model (từ API response)
- ⬜ Transaction Model
- ⬜ Category Model
- ⬜ API Response wrapper

---

### **PHASE 3: Authentication (4-5 giờ)**

#### 3.1 Login Screen
- ⬜ UI: Email & Password fields
- ⬜ Validation
- ⬜ Call login API
- ⬜ Save tokens
- ⬜ Navigate to home

#### 3.2 Register Screen
- ⬜ UI: Email, Password, Full Name, Phone
- ⬜ Validation
- ⬜ Call register API
- ⬜ Save tokens
- ⬜ Navigate to home

#### 3.3 Auth Provider
- ⬜ Login logic
- ⬜ Register logic
- ⬜ Logout logic
- ⬜ Check auth status
- ⬜ Auto refresh token

#### 3.4 Splash Screen
- ⬜ Check if user logged in
- ⬜ Navigate to Login or Home

---

### **PHASE 4: Home Dashboard (3-4 giờ)**

#### 4.1 Dashboard Screen
- ⬜ Summary cards (Income, Expense, Balance)
- ⬜ Recent transactions list
- ⬜ Chart: Spending by category
- ⬜ Quick action buttons

#### 4.2 API Integration
- ⬜ Get transaction summary
- ⬜ Get recent transactions
- ⬜ Get spending by category

---

### **PHASE 5: Transactions (5-6 giờ)**

#### 5.1 Transaction List Screen
- ⬜ List all transactions với pagination
- ⬜ Filter by type (income/expense)
- ⬜ Filter by category
- ⬜ Filter by date range
- ⬜ Sort options
- ⬜ Pull to refresh
- ⬜ Infinite scroll

#### 5.2 Add Transaction Screen
- ⬜ Amount input
- ⬜ Type selector (income/expense)
- ⬜ Category picker
- ⬜ Date picker
- ⬜ Payment method selector
- ⬜ Description field
- ⬜ Tags input
- ⬜ Save button
- ⬜ Call create transaction API

#### 5.3 Transaction Detail Screen
- ⬜ Show full transaction info
- ⬜ Edit button
- ⬜ Delete button
- ⬜ Call update/delete APIs

#### 5.4 Edit Transaction Screen
- ⬜ Pre-fill form with existing data
- ⬜ Update transaction API

---

### **PHASE 6: Categories (2-3 giờ)**

#### 6.1 Category List Screen
- ⬜ Show all categories (default + custom)
- ⬜ Filter by type
- ⬜ Add new category button

#### 6.2 Add/Edit Category Screen
- ⬜ Name input
- ⬜ Type selector
- ⬜ Icon picker
- ⬜ Color picker
- ⬜ Save category API

---

### **PHASE 7: Analytics (3-4 giờ)**

#### 7.1 Analytics Screen
- ⬜ Monthly summary
- ⬜ Pie chart: Spending by category
- ⬜ Bar chart: Daily/Weekly spending
- ⬜ Line chart: Income vs Expense trend
- ⬜ Export report (optional)

---

### **PHASE 8: Profile & Settings (2-3 giờ)**

#### 8.1 Profile Screen
- ⬜ User info display
- ⬜ Edit profile (optional)
- ⬜ Change password (optional)
- ⬜ Logout button

#### 8.2 Settings Screen
- ⬜ Currency selection
- ⬜ Language selection
- ⬜ Theme (light/dark mode)
- ⬜ Notification settings

---

### **PHASE 9: Polish & Testing (3-4 giờ)**

#### 9.1 UI/UX Improvements
- ⬜ Loading states
- ⬜ Empty states
- ⬜ Error states
- ⬜ Success messages
- ⬜ Animations

#### 9.2 Testing
- ⬜ Test all APIs
- ⬜ Test offline handling
- ⬜ Test token refresh
- ⬜ Fix bugs

---

## 🎨 Design Guidelines

### Colors (Expense Manager Theme)
```dart
Primary: #3498db (Blue)
Success: #27ae60 (Green - Income)
Danger: #e74c3c (Red - Expense)
Warning: #f39c12 (Orange)
Dark: #2c3e50
Light: #ecf0f1
```

### Key Screens Priority
1. **Must Have** (Core functionality)
   - Login
   - Register
   - Dashboard
   - Transaction List
   - Add Transaction
   
2. **Should Have** (Important features)
   - Transaction Detail
   - Edit Transaction
   - Categories
   - Analytics
   - Profile

3. **Nice to Have** (Enhancements)
   - Advanced filters
   - Export reports
   - Dark mode
   - Push notifications

---

## 📊 API Integration Checklist

### Authentication APIs (5 endpoints)
- ⬜ POST /api/auth/register
- ⬜ POST /api/auth/login
- ⬜ POST /api/auth/refresh
- ⬜ POST /api/auth/logout
- ⬜ GET /api/auth/profile

### Category APIs (5 endpoints)
- ⬜ GET /api/categories
- ⬜ GET /api/categories/:id
- ⬜ POST /api/categories
- ⬜ PUT /api/categories/:id
- ⬜ DELETE /api/categories/:id

### Transaction APIs (7 endpoints)
- ⬜ POST /api/transactions
- ⬜ GET /api/transactions
- ⬜ GET /api/transactions/:id
- ⬜ PUT /api/transactions/:id
- ⬜ DELETE /api/transactions/:id
- ⬜ GET /api/transactions/summary
- ⬜ GET /api/transactions/spending-by-category

---

## ⏱️ Timeline Estimate

**Total: 25-32 giờ**

- Week 1 (8-10h): Phase 1-3 (Setup + Auth)
- Week 2 (8-10h): Phase 4-6 (Dashboard + Transactions + Categories)
- Week 3 (6-8h): Phase 7-8 (Analytics + Profile)
- Week 4 (3-4h): Phase 9 (Polish + Testing)

---

## 🚀 Quick Start

### Bước 1: Cài đặt dependencies
```bash
cd frontend
flutter pub get
```

### Bước 2: Chạy app
```bash
flutter run
```

### Bước 3: Đảm bảo backend đang chạy
```bash
cd backend
npm run dev
```

---

## 📝 Notes

1. **Backend API Base URL:** `http://localhost:3000` (development)
2. **Backend đã có đầy đủ 17 endpoints** - Tất cả đã test thành công
3. **Authentication:** JWT với Bearer token
4. **Token refresh:** Tự động khi access token hết hạn
5. **13 Default Categories:** Được tạo tự động khi register

---

## 🎯 Success Criteria

✅ **Minimum Viable Product (MVP):**
- User có thể đăng ký/đăng nhập
- User có thể thêm/xem/sửa/xóa giao dịch
- User có thể xem tổng thu/chi
- User có thể xem giao dịch theo danh mục

✅ **Full Feature:**
- Tất cả 17 APIs được tích hợp
- UI/UX đẹp, mượt mà
- Charts & analytics hoạt động
- Offline handling
- Error handling tốt

---

**Ready to start? Let's build! 🚀**
