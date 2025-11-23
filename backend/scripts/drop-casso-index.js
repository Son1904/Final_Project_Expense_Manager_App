const mongoose = require('mongoose');
require('dotenv').config();

async function dropCassoIndex() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const db = mongoose.connection.db;
    const collection = db.collection('transactions');

    // Get all indexes
    const indexes = await collection.indexes();
    console.log('Current indexes:', indexes.map(i => i.name));

    // Drop cassoTransactionId index if exists
    try {
      await collection.dropIndex('cassoTransactionId_1');
      console.log('✓ Dropped cassoTransactionId_1 index');
    } catch (error) {
      if (error.code === 27) {
        console.log('ℹ cassoTransactionId_1 index does not exist (already dropped)');
      } else {
        throw error;
      }
    }

    // Also remove cassoTransactionId and syncedFromCasso fields from existing documents
    const result = await collection.updateMany(
      {},
      {
        $unset: {
          cassoTransactionId: '',
          syncedFromCasso: '',
        },
      }
    );

    console.log(`✓ Removed Casso fields from ${result.modifiedCount} documents`);

    console.log('\n✅ Cleanup completed successfully');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

dropCassoIndex();
