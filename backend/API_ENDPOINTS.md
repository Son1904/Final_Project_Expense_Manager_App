# 📋 API ENDPOINTS DOCUMENTATION

## Base Information
- **Base URL:** `http://localhost:3000`
- **Server Port:** 3000
- **Start Server:** `npm run dev`

---

## 🔐 AUTHENTICATION APIs

### 1. Register User
**Create a new user account**

- **Method:** `POST`
- **Endpoint:** `/api/auth/register`
- **Authentication:** None (Public)
- **Request Body:**
```json
{
  "email": "test@example.com",
  "password": "password123",
  "fullName": "Test User",
  "phone": "0901234567"
}
```
- **Success Response (201):**
```json
{
  "status": "success",
  "message": "Registration successful",
  "data": {
    "user": {
      "id": "uuid",
      "email": "test@example.com",
      "fullName": "Test User",
      "phone": "0901234567"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### 2. Login
**Authenticate user and get tokens**

- **Method:** `POST`
- **Endpoint:** `/api/auth/login`
- **Authentication:** None (Public)
- **Request Body:**
```json
{
  "email": "test@example.com",
  "password": "password123"
}
```
- **Success Response (200):**
```json
{
  "status": "success",
  "message": "Login successful",
  "data": {
    "user": {
      "id": "uuid",
      "email": "test@example.com",
      "fullName": "Test User",
      "phone": "0901234567"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### 3. Get Profile
**Get authenticated user profile**

- **Method:** `GET`
- **Endpoint:** `/api/auth/profile`
- **Authentication:** Required (Bearer Token)
- **Headers:**
```
Authorization: Bearer {accessToken}
```
- **Success Response (200):**
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "uuid",
      "email": "test@example.com",
      "fullName": "Test User",
      "phone": "0901234567",
      "avatarUrl": null,
      "emailVerified": false,
      "phoneVerified": false,
      "createdAt": "2025-10-24T05:22:42.723Z"
    }
  }
}
```

---

### 4. Refresh Access Token
**Get new access token using refresh token**

- **Method:** `POST`
- **Endpoint:** `/api/auth/refresh`
- **Authentication:** None (uses refresh token)
- **Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```
- **Success Response (200):**
```json
{
  "status": "success",
  "message": "Access token refreshed",
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

---

### 5. Logout
**Revoke refresh token**

- **Method:** `POST`
- **Endpoint:** `/api/auth/logout`
- **Authentication:** Required (Bearer Token)
- **Headers:**
```
Authorization: Bearer {accessToken}
```
- **Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```
- **Success Response (200):**
```json
{
  "status": "success",
  "message": "Logout successful"
}
```

---

## 📁 CATEGORY APIs

### 6. Get All Categories
**Get all categories for authenticated user (default + custom)**

- **Method:** `GET`
- **Endpoint:** `/api/categories`
- **Authentication:** Required (Bearer Token)
- **Headers:**
```
Authorization: Bearer {accessToken}
```
- **Query Parameters (Optional):**
  - `type` - Filter by type: `income` or `expense`
  
- **Example:** `/api/categories?type=expense`

- **Success Response (200):**
```json
{
  "status": "success",
  "data": {
    "categories": [
      {
        "_id": "68fb0d22eeebe67766933da6",
        "userId": "uuid",
        "name": "Food & Dining",
        "type": "expense",
        "icon": "restaurant",
        "color": "#e74c3c",
        "isDefault": true,
        "isActive": true,
        "createdAt": "2025-10-24T05:22:42.736Z",
        "updatedAt": "2025-10-24T05:22:42.736Z"
      }
    ]
  }
}
```

---

### 7. Get Category by ID
**Get single category details**

- **Method:** `GET`
- **Endpoint:** `/api/categories/{categoryId}`
- **Authentication:** Required (Bearer Token)
- **Headers:**
```
Authorization: Bearer {accessToken}
```
- **Success Response (200):**
```json
{
  "status": "success",
  "data": {
    "category": {
      "_id": "68fb0d22eeebe67766933da6",
      "userId": "uuid",
      "name": "Food & Dining",
      "type": "expense",
      "icon": "restaurant",
      "color": "#e74c3c",
      "isDefault": true,
      "isActive": true
    }
  }
}
```

---

### 8. Create Category
**Create a new custom category**

- **Method:** `POST`
- **Endpoint:** `/api/categories`
- **Authentication:** Required (Bearer Token)
- **Headers:**
```
Authorization: Bearer {accessToken}
```
- **Request Body:**
```json
{
  "name": "Coffee & Tea",
  "type": "expense",
  "icon": "coffee",
  "color": "#8b4513"
}
```
- **Success Response (201):**
```json
{
  "status": "success",
  "message": "Category created successfully",
  "data": {
    "category": {
      "_id": "68fb4d3feeebe67766933dc4",
      "userId": "uuid",
      "name": "Coffee & Tea",
      "type": "expense",
      "icon": "coffee",
      "color": "#8b4513",
      "isDefault": false,
      "isActive": true,
      "createdAt": "2025-10-24T09:56:15.006Z",
      "updatedAt": "2025-10-24T09:56:15.006Z"
    }
  }
}
```

---

### 9. Update Category
**Update existing category (custom only, cannot edit default categories)**

- **Method:** `PUT`
- **Endpoint:** `/api/categories/{categoryId}`
- **Authentication:** Required (Bearer Token)
- **Headers:**
```
Authorization: Bearer {accessToken}
```
- **Request Body:**
```json
{
  "name": "Updated Name",
  "icon": "new-icon",
  "color": "#ff0000"
}
```
- **Success Response (200):**
```json
{
  "status": "success",
  "message": "Category updated successfully",
  "data": {
    "category": {
      "_id": "68fb4d3feeebe67766933dc4",
      "name": "Updated Name",
      "icon": "new-icon",
      "color": "#ff0000"
    }
  }
}
```

---

### 10. Delete Category
**Delete custom category (cannot delete default categories or categories with transactions)**

- **Method:** `DELETE`
- **Endpoint:** `/api/categories/{categoryId}`
- **Authentication:** Required (Bearer Token)
- **Headers:**
```
Authorization: Bearer {accessToken}
```
- **Success Response (200):**
```json
{
  "status": "success",
  "message": "Category deleted successfully"
}
```

---

## 💰 TRANSACTION APIs

### 11. Create Transaction
**Create a new transaction**

- **Method:** `POST`
- **Endpoint:** `/api/transactions`
- **Authentication:** Required (Bearer Token)
- **Headers:**
```
Authorization: Bearer {accessToken}
```
- **Request Body:**
```json
{
  "amount": 150000,
  "type": "expense",
  "category": "68fb0d22eeebe67766933da6",
  "description": "Ăn trưa quán phở",
  "paymentMethod": "cash",
  "date": "2025-10-24",
  "tags": ["lunch", "food"],
  "location": {
    "name": "Phở 24",
    "address": "123 Nguyen Hue"
  },
  "notes": "Delicious pho"
}
```
- **Required fields:** `amount`, `type`, `category`
- **Optional fields:** `description`, `date`, `paymentMethod`, `bankAccountId`, `tags`, `location`, `notes`

- **Success Response (201):**
```json
{
  "status": "success",
  "message": "Transaction created successfully",
  "data": {
    "transaction": {
      "_id": "68fb0f36eeebe67766933db6",
      "userId": "uuid",
      "amount": 150000,
      "type": "expense",
      "category": {
        "_id": "68fb0d22eeebe67766933da6",
        "name": "Food & Dining",
        "type": "expense",
        "icon": "restaurant",
        "color": "#e74c3c"
      },
      "description": "Ăn trưa quán phở",
      "date": "2025-10-24T00:00:00.000Z",
      "paymentMethod": "cash",
      "tags": ["lunch", "food"],
      "isRecurring": false,
      "syncedFromCasso": false,
      "createdAt": "2025-10-24T05:31:34.905Z",
      "updatedAt": "2025-10-24T05:31:34.905Z"
    }
  }
}
```

---

### 12. Get All Transactions
**Get transactions with filtering, sorting, and pagination**

- **Method:** `GET`
- **Endpoint:** `/api/transactions`
- **Authentication:** Required (Bearer Token)
- **Headers:**
```
Authorization: Bearer {accessToken}
```
- **Query Parameters (All Optional):**
  - `type` - Filter by type: `income` or `expense`
  - `category` - Filter by category ID
  - `startDate` - Filter from date (YYYY-MM-DD)
  - `endDate` - Filter to date (YYYY-MM-DD)
  - `paymentMethod` - Filter by payment method: `cash`, `card`, `bank_transfer`, etc.
  - `page` - Page number (default: 1)
  - `limit` - Items per page (default: 20)
  - `sortBy` - Sort field (default: `date`)
  - `sortOrder` - Sort order: `asc` or `desc` (default: `desc`)

- **Example:** `/api/transactions?type=expense&startDate=2025-10-01&endDate=2025-10-31&page=1&limit=20&sortBy=date&sortOrder=desc`

- **Success Response (200):**
```json
{
  "status": "success",
  "data": {
    "transactions": [
      {
        "_id": "68fb0f36eeebe67766933db6",
        "userId": "uuid",
        "amount": 150000,
        "type": "expense",
        "category": {
          "_id": "68fb0d22eeebe67766933da6",
          "name": "Food & Dining",
          "type": "expense",
          "icon": "restaurant",
          "color": "#e74c3c"
        },
        "description": "Ăn trưa quán phở",
        "date": "2025-10-24T00:00:00.000Z",
        "paymentMethod": "cash"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 1,
      "pages": 1
    }
  }
}
```

---

### 13. Get Transaction by ID
**Get single transaction details**

- **Method:** `GET`
- **Endpoint:** `/api/transactions/{transactionId}`
- **Authentication:** Required (Bearer Token)
- **Headers:**
```
Authorization: Bearer {accessToken}
```
- **Success Response (200):**
```json
{
  "status": "success",
  "data": {
    "transaction": {
      "_id": "68fb0f36eeebe67766933db6",
      "userId": "uuid",
      "amount": 150000,
      "type": "expense",
      "category": {
        "_id": "68fb0d22eeebe67766933da6",
        "name": "Food & Dining",
        "icon": "restaurant",
        "color": "#e74c3c"
      },
      "description": "Ăn trưa quán phở",
      "date": "2025-10-24T00:00:00.000Z",
      "paymentMethod": "cash"
    }
  }
}
```

---

### 14. Update Transaction
**Update existing transaction**

- **Method:** `PUT`
- **Endpoint:** `/api/transactions/{transactionId}`
- **Authentication:** Required (Bearer Token)
- **Headers:**
```
Authorization: Bearer {accessToken}
```
- **Request Body (all fields optional):**
```json
{
  "amount": 200000,
  "description": "Ăn trưa quán phở + trà đá",
  "paymentMethod": "card"
}
```
- **Success Response (200):**
```json
{
  "status": "success",
  "message": "Transaction updated successfully",
  "data": {
    "transaction": {
      "_id": "68fb0f36eeebe67766933db6",
      "amount": 200000,
      "description": "Ăn trưa quán phở + trà đá",
      "updatedAt": "2025-10-24T09:53:29.554Z"
    }
  }
}
```

---

### 15. Delete Transaction
**Delete transaction**

- **Method:** `DELETE`
- **Endpoint:** `/api/transactions/{transactionId}`
- **Authentication:** Required (Bearer Token)
- **Headers:**
```
Authorization: Bearer {accessToken}
```
- **Success Response (200):**
```json
{
  "status": "success",
  "message": "Transaction deleted successfully"
}
```

---

### 16. Get Transaction Summary
**Get income, expense, balance summary for date range**

- **Method:** `GET`
- **Endpoint:** `/api/transactions/summary`
- **Authentication:** Required (Bearer Token)
- **Headers:**
```
Authorization: Bearer {accessToken}
```
- **Query Parameters (Required):**
  - `startDate` - Start date (YYYY-MM-DD)
  - `endDate` - End date (YYYY-MM-DD)

- **Example:** `/api/transactions/summary?startDate=2025-10-01&endDate=2025-10-31`

- **Success Response (200):**
```json
{
  "status": "success",
  "data": {
    "summary": {
      "income": 0,
      "expense": 150000,
      "balance": -150000,
      "transactionCount": 1
    }
  }
}
```

---

### 17. Get Spending by Category
**Get expense breakdown by category for date range**

- **Method:** `GET`
- **Endpoint:** `/api/transactions/spending-by-category`
- **Authentication:** Required (Bearer Token)
- **Headers:**
```
Authorization: Bearer {accessToken}
```
- **Query Parameters (Required):**
  - `startDate` - Start date (YYYY-MM-DD)
  - `endDate` - End date (YYYY-MM-DD)

- **Example:** `/api/transactions/spending-by-category?startDate=2025-10-01&endDate=2025-10-31`

- **Success Response (200):**
```json
{
  "status": "success",
  "data": {
    "spending": [
      {
        "_id": "68fb0d22eeebe67766933da6",
        "total": 150000,
        "count": 1,
        "categoryName": "Food & Dining",
        "categoryIcon": "restaurant",
        "categoryColor": "#e74c3c"
      }
    ]
  }
}
```

---

## 📊 Testing Summary

**Total Endpoints:** 17
- Authentication: 5 endpoints
- Categories: 5 endpoints
- Transactions: 7 endpoints

**Testing Status:** ✅ All endpoints tested successfully with Thunder Client

---

## 🔧 Common Error Responses

### 400 Bad Request
```json
{
  "status": "fail",
  "message": "Validation error message"
}
```

### 401 Unauthorized
```json
{
  "status": "fail",
  "message": "Authentication required. Please log in."
}
```

### 403 Forbidden
```json
{
  "status": "fail",
  "message": "Cannot edit default categories"
}
```

### 404 Not Found
```json
{
  "status": "fail",
  "message": "Resource not found"
}
```

### 500 Internal Server Error
```json
{
  "status": "error",
  "message": "Internal server error"
}
```

---

## 📝 Notes

1. **Access Token:** Valid for 15 minutes
2. **Refresh Token:** Valid for 7 days
3. **Rate Limiting:** 100 requests per 15 minutes per IP
4. **Default Categories:** 13 categories auto-created on registration
   - 9 Expense: Food & Dining, Transportation, Shopping, Entertainment, Bills & Utilities, Healthcare, Education, Other Expense
   - 4 Income: Salary, Freelance, Investment, Gift, Other Income
5. **Payment Methods:** cash, card, bank_transfer, e_wallet, other
6. **Date Format:** ISO 8601 (YYYY-MM-DD or full ISO string)

---

**Last Updated:** October 25, 2025
