// Budget API Test Script
// Run with: node test-budget-api.js

const baseURL = 'http://localhost:3000/api';
let token = '';
let budgetId = '';

// Test user credentials
const testUser = {
  email: 'user@example.com',
  password: 'password123'
};

// Helper function to make API calls
async function apiCall(method, endpoint, body = null) {
  const headers = {
    'Content-Type': 'application/json',
  };
  
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const options = {
    method,
    headers,
  };

  if (body) {
    options.body = JSON.stringify(body);
  }

  const response = await fetch(`${baseURL}${endpoint}`, options);
  const data = await response.json();
  
  console.log(`\n${'='.repeat(80)}`);
  console.log(`${method} ${endpoint}`);
  console.log(`Status: ${response.status} ${response.statusText}`);
  console.log('Response:', JSON.stringify(data, null, 2));
  
  return { response, data };
}

async function runTests() {
  try {
    console.log('\n🚀 Starting Budget API Tests...\n');

    // 1. Login to get token
    console.log('📝 Step 1: Login');
    const loginResult = await apiCall('POST', '/auth/login', testUser);
    if (loginResult.data.status === 'success') {
      token = loginResult.data.data.token;
      console.log('✅ Login successful! Token obtained.');
    } else {
      console.error('❌ Login failed!');
      return;
    }

    // 2. Get categories to use in budget
    console.log('\n📝 Step 2: Get Categories');
    const categoriesResult = await apiCall('GET', '/categories');
    let categoryId = '';
    if (categoriesResult.data.status === 'success' && categoriesResult.data.data.categories.length > 0) {
      // Get first expense category
      const expenseCategories = categoriesResult.data.data.categories.filter(c => c.type === 'expense');
      if (expenseCategories.length > 0) {
        categoryId = expenseCategories[0]._id;
        console.log(`✅ Using category: ${expenseCategories[0].name} (ID: ${categoryId})`);
      }
    }

    // 3. Create a new budget
    console.log('\n📝 Step 3: Create Budget');
    const now = new Date();
    const startDate = new Date(now.getFullYear(), now.getMonth(), 1); // First day of current month
    const endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0); // Last day of current month
    
    const newBudget = {
      name: 'Monthly Food Budget',
      amount: 5000000, // 5 million VND
      period: 'monthly',
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString(),
      categories: categoryId ? [categoryId] : [],
      alertThreshold: 80,
      alertEnabled: true,
      repeatAutomatically: true
    };

    const createResult = await apiCall('POST', '/budgets', newBudget);
    if (createResult.data.status === 'success') {
      budgetId = createResult.data.data.budget._id;
      console.log(`✅ Budget created! ID: ${budgetId}`);
    }

    // 4. Get all budgets
    console.log('\n📝 Step 4: Get All Budgets');
    await apiCall('GET', '/budgets');

    // 5. Get active budgets only
    console.log('\n📝 Step 5: Get Active Budgets');
    await apiCall('GET', '/budgets/active');

    // 6. Get budget status
    console.log('\n📝 Step 6: Get Budget Status');
    await apiCall('GET', '/budgets/status');

    // 7. Get single budget by ID
    if (budgetId) {
      console.log('\n📝 Step 7: Get Budget by ID');
      await apiCall('GET', `/budgets/${budgetId}`);
    }

    // 8. Update budget
    if (budgetId) {
      console.log('\n📝 Step 8: Update Budget');
      const updateData = {
        amount: 6000000, // Increase to 6 million
        alertThreshold: 75
      };
      await apiCall('PUT', `/budgets/${budgetId}`, updateData);
    }

    // 9. Refresh budget spent amount
    if (budgetId) {
      console.log('\n📝 Step 9: Refresh Budget');
      await apiCall('POST', `/budgets/${budgetId}/refresh`);
    }

    // 10. Refresh all budgets
    console.log('\n📝 Step 10: Refresh All Budgets');
    await apiCall('POST', '/budgets/refresh-all');

    // 11. Create another budget for testing filters
    console.log('\n📝 Step 11: Create Yearly Budget');
    const yearlyBudget = {
      name: 'Annual Entertainment Budget',
      amount: 20000000, // 20 million VND
      period: 'yearly',
      startDate: new Date(now.getFullYear(), 0, 1).toISOString(), // Jan 1
      endDate: new Date(now.getFullYear(), 11, 31).toISOString(), // Dec 31
      categories: [],
      alertThreshold: 90,
      alertEnabled: true,
      repeatAutomatically: false
    };
    await apiCall('POST', '/budgets', yearlyBudget);

    // 12. Filter budgets by period
    console.log('\n📝 Step 12: Filter Budgets by Period (monthly)');
    await apiCall('GET', '/budgets?period=monthly');

    // 13. Soft delete budget
    if (budgetId) {
      console.log('\n📝 Step 13: Soft Delete Budget');
      await apiCall('DELETE', `/budgets/${budgetId}`);
    }

    // 14. Get budgets including inactive
    console.log('\n📝 Step 14: Get All Budgets (including inactive)');
    await apiCall('GET', '/budgets?active=false');

    console.log('\n✅ All tests completed!\n');

  } catch (error) {
    console.error('\n❌ Test failed with error:', error);
  }
}

// Run the tests
runTests();
