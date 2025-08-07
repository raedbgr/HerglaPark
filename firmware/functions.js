const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

// Coordinates of your polygon (must be in clockwise or counter-clockwise order)
const parkPolygon = [
  { lat: 36.0256027822365, lng: 10.489141022478105 },
  { lat: 36.02614451424541, lng: 10.490908117303828 },
  { lat: 36.025210669137984, lng: 10.491392951982972 },
  { lat: 36.0247514815727, lng: 10.490442420835707 },
  { lat: 36.02444191540107, lng: 10.490557250098494 },
  { lat: 36.02449866928829, lng: 10.490888979089485 },
  { lat: 36.02423553728472, lng: 10.491073981796001 },
  { lat: 36.02380730096865, lng: 10.490187244685464 },
  { lat: 36.025576985378315, lng: 10.48913464307943 },
];

// Helper function to check if a point is in a polygon (Ray casting algorithm)
function isPointInPolygon(point, polygon) {
  let inside = false;
  for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    const xi = polygon[i].lat, yi = polygon[i].lng;
    const xj = polygon[j].lat, yj = polygon[j].lng;

    const intersect = ((yi > point.lng) !== (yj > point.lng)) &&
      (point.lat < (xj - xi) * (point.lng - yi) / (yj - yi) + xi);
    if (intersect) inside = !inside;
  }
  return inside;
}

// Generate random point in bounding box and check if in polygon
function generateRandomPointInPolygon(polygon) {
  const minLat = Math.min(...polygon.map(p => p.lat));
  const maxLat = Math.max(...polygon.map(p => p.lat));
  const minLng = Math.min(...polygon.map(p => p.lng));
  const maxLng = Math.max(...polygon.map(p => p.lng));

  while (true) {
    const lat = minLat + Math.random() * (maxLat - minLat);
    const lng = minLng + Math.random() * (maxLng - minLng);
    const point = { lat, lng };

    if (isPointInPolygon(point, polygon)) {
      return point;
    }
  }
}

exports.manageDailyChests = functions.pubsub
  .schedule('0 5 * * *') // Every day at 5:00 AM UTC (adjust for your time zone)
  .timeZone('Europe/Paris') // ⬅️ Set this to your local time zone
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();

    // 1. Delete expired chests
    const expiredSnapshot = await db.collection('chests')
      .where('expiresAt', '<=', now)
      .get();

    const deleteBatch = db.batch();
    expiredSnapshot.docs.forEach(doc => deleteBatch.delete(doc.ref));
    await deleteBatch.commit();
    console.log(`✅ Deleted ${expiredSnapshot.size} expired chests.`);

    // 2. Generate 20 new chests
    const chestPromises = [];

    for (let i = 0; i < 20; i++) {
      const point = generateRandomPointInPolygon(parkPolygon);
      const chestId = db.collection('chests').doc().id;
      const chestData = {
        id: chestId,
        location: {
          lat: point.lat,
          lng: point.lng,
        },
        spawnedAt: admin.firestore.Timestamp.now(),
        expiresAt: admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 hours from now
        )
      };

      chestPromises.push(db.collection('chests').doc(chestId).set(chestData));
    }

    await Promise.all(chestPromises);
    console.log(`✅ Generated 20 new chests.`);
  });
