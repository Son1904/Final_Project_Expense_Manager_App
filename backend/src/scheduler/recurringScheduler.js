/**
 * Recurring Transaction Scheduler
 * Runs every hour to check for due recurring transactions
 * Creates actual transactions and notifications automatically
 */

const cron = require('node-cron');
const RecurringTransaction = require('../models/RecurringTransaction');
const Transaction = require('../models/Transaction');
const { createNotification } = require('../controllers/notificationController');
const logger = require('../utils/logger');

/**
 * Process all due recurring transactions
 * Creates actual Transaction documents and updates scheduling
 */
async function processRecurringTransactions() {
  try {
    // Find all recurring transactions that are due
    const dueTransactions = await RecurringTransaction.getDueTransactions();

    if (dueTransactions.length === 0) {
      return; // Nothing to process
    }

    logger.info(`Processing ${dueTransactions.length} due recurring transactions`);

    let successCount = 0;
    let errorCount = 0;

    for (const recurring of dueTransactions) {
      try {
        const now = new Date();
        let execDate = new Date(recurring.nextExecutionDate);
        let createdCount = 0;
        let lastTransaction = null;

        // Loop to backfill all missed executions
        while (execDate <= now) {
          // Check if end date has passed
          if (recurring.endDate && execDate > recurring.endDate) {
            recurring.isActive = false;
            logger.info(`Recurring transaction ${recurring._id} completed (end date reached)`);
            break;
          }

          // 1. Create the actual transaction with the HISTORICAL scheduled date
          lastTransaction = await Transaction.create({
            userId: recurring.userId,
            amount: recurring.amount,
            type: recurring.type,
            category: recurring.category._id,
            description: recurring.description || `Recurring: ${recurring.category.name}`,
            date: new Date(execDate), // IMPORTANT: Use the exact scheduled date, not "now"
            paymentMethod: recurring.paymentMethod,
            notes: recurring.notes ? `[Auto] ${recurring.notes}` : '[Auto] Recurring transaction',
            isRecurring: true,
            recurringConfig: {
              frequency: recurring.frequency
            }
          });

          // 2. Update recurring transaction tracking
          recurring.lastExecutedAt = new Date(execDate);
          recurring.executionCount += 1;
          
          // 3. Advance to the next date
          execDate = recurring.calculateNextDate(execDate);
          createdCount++;
        }

        if (createdCount > 0) {
          // Save the advanced nextExecutionDate
          recurring.nextExecutionDate = execDate;
          await recurring.save();

          // 4. Create ONE notification for the user (even if multiple were backfilled)
          try {
            const formattedAmount = new Intl.NumberFormat('en-US', {
              style: 'currency',
              currency: 'USD',
            }).format(recurring.amount);

            let message = `${recurring.type === 'expense' ? 'Expense' : 'Income'} of ${formattedAmount} for "${recurring.category.name}" has been automatically recorded.`;
            if (createdCount > 1) {
              message = `${createdCount} missing transactions (totaling ${formattedAmount}) have been automatically backfilled up to today.`;
            }

            await createNotification(recurring.userId, {
              type: 'RECURRING_UPCOMING',
              title: createdCount > 1 ? 'Recurring transactions backfilled' : 'Recurring transaction executed',
              message: message,
              priority: 'LOW',
              referenceType: 'TRANSACTION',
              referenceId: lastTransaction._id.toString(),
              metadata: {
                amount: recurring.amount,
                type: recurring.type,
                categoryName: recurring.category.name,
                recurringId: recurring._id.toString(),
                backfilledCount: createdCount
              },
            });
          } catch (notifError) {
            logger.error(`Failed to create notification for recurring ${recurring._id}:`, notifError);
          }

          successCount++;
        }
      } catch (error) {
        errorCount++;
        logger.error(`Failed to process recurring transaction ${recurring._id}:`, error);
      }
    }

    logger.info(
      `Recurring transactions processed: ${successCount} success, ${errorCount} errors`
    );
  } catch (error) {
    logger.error('Error in recurring transaction scheduler:', error);
  }
}

/**
 * Start the recurring transaction scheduler
 * Runs every hour at minute 0 (e.g., 8:00, 9:00, 10:00, ...)
 */
function startRecurringScheduler() {
  // Schedule: Run every hour at minute 0
  // Cron format: second minute hour dayOfMonth month dayOfWeek
  cron.schedule('0 0 * * * *', async () => {
    logger.info('Running recurring transaction scheduler...');
    await processRecurringTransactions();
  });

  logger.info('Recurring transaction scheduler started (runs every hour)');

  // Also run once on startup to catch any missed executions
  setTimeout(async () => {
    logger.info('Running initial recurring transaction check...');
    await processRecurringTransactions();
  }, 5000); // Wait 5 seconds after startup
}

module.exports = {
  startRecurringScheduler,
  processRecurringTransactions, // Export for testing
};
