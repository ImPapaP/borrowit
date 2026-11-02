/// Sample catalog used by the "Load sample equipment" button (debug builds
/// only). Each `image` matches a file in assets/equipment/.
const List<Map<String, Object>> sampleEquipment = [
  {
    'id': 'laptop',
    'name': 'Laptop',
    'description':
        '14-inch laptop with Core i5 processor, 8 GB RAM and 256 GB SSD. '
            'Comes with charger and carrying sleeve. Office apps installed.',
    'category': 'Computers',
    'image': 'laptop.png',
    'quantityAvailable': 5,
    'quantityTotal': 8,
    'location': 'IT Office, Room 101',
    'condition': 'Good',
  },
  {
    'id': 'projector',
    'name': 'LCD Projector',
    'description':
        '3,500-lumen projector for classrooms and presentations. Includes '
            'power cord, remote control and VGA/HDMI inputs.',
    'category': 'Audio-Visual',
    'image': 'projector.png',
    'quantityAvailable': 3,
    'quantityTotal': 4,
    'location': 'AV Room, 2nd Floor',
    'condition': 'Good',
  },
  {
    'id': 'camera',
    'name': 'DSLR Camera',
    'description':
        '24 MP DSLR with 18-55 mm kit lens, one battery, charger and a '
            '32 GB memory card. Handle with care.',
    'category': 'Photography',
    'image': 'camera.png',
    'quantityAvailable': 2,
    'quantityTotal': 3,
    'location': 'Media Center',
    'condition': 'Very good',
  },
  {
    'id': 'hdmi-cable',
    'name': 'HDMI Cable (3 m)',
    'description':
        '3-meter high-speed HDMI cable for connecting laptops to '
            'projectors, TVs and monitors.',
    'category': 'Cables & Accessories',
    'image': 'hdmi_cable.png',
    'quantityAvailable': 10,
    'quantityTotal': 12,
    'location': 'IT Office, Room 101',
    'condition': 'Good',
  },
  {
    'id': 'extension-cord',
    'name': 'Extension Cord (5 m)',
    'description':
        '4-socket extension cord with surge protection and on/off switch. '
            '5-meter cable.',
    'category': 'Cables & Accessories',
    'image': 'extension_cord.png',
    'quantityAvailable': 6,
    'quantityTotal': 6,
    'location': 'Maintenance Office',
    'condition': 'Good',
  },
  {
    'id': 'microphone',
    'name': 'Wireless Microphone',
    'description':
        'Handheld wireless microphone with receiver. Uses 2 AA batteries '
            '(included). Range up to 30 meters.',
    'category': 'Audio',
    'image': 'microphone.png',
    'quantityAvailable': 0,
    'quantityTotal': 4,
    'location': 'AV Room, 2nd Floor',
    'condition': 'Good',
  },
  {
    'id': 'tripod',
    'name': 'Camera Tripod',
    'description':
        'Adjustable aluminum tripod (up to 160 cm) with quick-release '
            'plate. Fits most cameras and phone holders.',
    'category': 'Photography',
    'image': 'tripod.png',
    'quantityAvailable': 4,
    'quantityTotal': 4,
    'location': 'Media Center',
    'condition': 'Good',
  },
  {
    'id': 'speaker',
    'name': 'Portable Speaker',
    'description':
        'Bluetooth speaker with built-in rechargeable battery and AUX '
            'input. Good for small rooms and outdoor events.',
    'category': 'Audio',
    'image': 'speaker.png',
    'quantityAvailable': 2,
    'quantityTotal': 3,
    'location': 'AV Room, 2nd Floor',
    'condition': 'Fair',
  },
];
