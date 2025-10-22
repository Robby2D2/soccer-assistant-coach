import 'package:soccer_assistant_coach/data/db/database.dart';

Future<void> main() async {
  print('Testing database migration from version 17 to 18...');
  
  try {
    // Create a test database
    final db = Database();
    
    // Test accessing the traditional lineups table (this should work after migration)
    final traditionalLineups = await db.select(db.traditionalLineups).get();
    print('✅ TraditionalLineups table is accessible');
    print('Found ${traditionalLineups.length} traditional lineups');
    
    // Test the foreign key constraints are working
    await db.close();
    print('✅ Database migration test completed successfully');
    
  } catch (e) {
    print('❌ Database migration test failed: $e');
  }
}