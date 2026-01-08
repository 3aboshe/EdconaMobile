import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:asn1lib/asn1lib.dart';
import 'api_service.dart';

/// Service for end-to-end encryption using RSA+AES hybrid encryption
class EncryptionService {
  static final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const int _aesKeySize = 32; // 256 bits
  static const int _rsaKeySize = 4096;

  /// Check if user has encryption keys
  static Future<bool> hasKeys(String userId) async {
    final privateKey = await _secureStorage.read(key: 'private_key_$userId');
    return privateKey != null && privateKey.isNotEmpty;
  }

  /// Generate RSA key pair for new user
  static Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>> generateRSAKeyPair() async {
    final keyParams = RSAKeyGeneratorParameters(
      BigInt.parse('65537'), // publicExponent
      _rsaKeySize,
      64, // certainty
    );

    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(random.nextInt(256));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));

    final keyGenerator = KeyGenerator('RSA')
      ..init(ParametersWithRandom(keyParams, secureRandom));

    final keyPair = keyGenerator.generateKeyPair();
    return AsymmetricKeyPair(
      keyPair.publicKey as RSAPublicKey,
      keyPair.privateKey as RSAPrivateKey,
    );
  }

  /// Store private key securely as PEM
  static Future<void> storePrivateKey(String userId, RSAPrivateKey privateKey) async {
    final privateKeyPem = _encodeRSAPrivateKeyToPEM(privateKey);
    await _secureStorage.write(
      key: 'private_key_$userId',
      value: privateKeyPem,
    );
  }

  /// Retrieve private key from PEM
  static Future<RSAPrivateKey?> getPrivateKey(String userId) async {
    final privateKeyPem = await _secureStorage.read(key: 'private_key_$userId');
    if (privateKeyPem == null) return null;
    try {
      return _decodeRSAPrivateKeyFromPEM(privateKeyPem);
    } catch (e) {
      if (kDebugMode) print('Error decoding private key: $e');
      return null;
    }
  }

  /// Generate and store keys for a new user
  static Future<bool> generateAndStoreKeys(String userId) async {
    try {
      final keyPair = await generateRSAKeyPair();
      await storePrivateKey(userId, keyPair.privateKey);

      // Upload public key to server
      final publicKeyPem = _encodeRSAPublicKeyToPEM(keyPair.publicKey);
      await ApiService.dio.post('/api/encryption/keys', data: {
        'publicKey': publicKeyPem,
      });

      return true;
    } catch (e) {
      if (kDebugMode) print('Error generating and storing keys: $e');
      return false;
    }
  }

  /// Encrypt message content with hybrid RSA+AES
  static Future<Map<String, dynamic>> encryptMessage(
    String plaintext,
    String receiverPublicKeyPem,
  ) async {
    try {
      // Generate ephemeral AES key
      final aesKey = enc.Key.fromSecureRandom(_aesKeySize);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(
        enc.AES(aesKey, mode: enc.AESMode.gcm),
      );

      // Encrypt message
      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      // Encrypt AES key with receiver's RSA public key
      final receiverPublicKey = _decodeRSAPublicKeyFromPEM(receiverPublicKeyPem);
      final encryptedAesKey = _encryptWithRSA(aesKey.bytes, receiverPublicKey);

      return {
        'encryptedContent': encrypted.base64,
        'encryptedAesKey': base64.encode(encryptedAesKey),
        'iv': iv.base64,
        'encryptionVersion': 1,
      };
    } catch (e) {
      if (kDebugMode) print('Error encrypting message: $e');
      rethrow;
    }
  }

  /// Decrypt message content
  static Future<String?> decryptMessage(
    Map<String, dynamic> encryptedMessage,
    String userId,
  ) async {
    try {
      final privateKey = await getPrivateKey(userId);
      if (privateKey == null) {
        if (kDebugMode) print('No private key found for user $userId');
        return null;
      }

      // Decrypt AES key with private RSA key
      final encryptedAesKey = base64.decode(encryptedMessage['encryptedAesKey']);
      final aesKeyBytes = _decryptWithRSA(encryptedAesKey, privateKey);
      final aesKey = enc.Key(aesKeyBytes);

      // Decrypt message
      final iv = enc.IV.fromBase64(encryptedMessage['iv']);
      final encrypter = enc.Encrypter(
        enc.AES(aesKey, mode: enc.AESMode.gcm),
      );

      final decrypted = encrypter.decrypt64(
        encryptedMessage['encryptedContent'],
        iv: iv,
      );

      return decrypted;
    } catch (e) {
      if (kDebugMode) print('Error decrypting message: $e');
      return null;
    }
  }

  /// Get public key from server
  static Future<String?> getPublicKey(String userId) async {
    try {
      final response = await ApiService.dio.get('/api/encryption/keys/$userId');
      if (response.statusCode == 200) {
        return response.data['publicKey'] as String;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error fetching public key: $e');
      return null;
    }
  }

  // Encode RSA private key to PEM format using asn1lib
  static String _encodeRSAPrivateKeyToPEM(RSAPrivateKey key) {
    final version = ASN1Integer(BigInt.from(0));
    final modulus = ASN1Integer(key.modulus!);
    final publicExponent = ASN1Integer(key.exponent!);
    final privateExponent = ASN1Integer(key.privateExponent!);
    final p = ASN1Integer(key.p!);
    final q = ASN1Integer(key.q!);

    // Calculate d mod (p-1)
    final dP = ASN1Integer(key.privateExponent! % (key.p! - BigInt.one));
    // Calculate d mod (q-1)
    final dQ = ASN1Integer(key.privateExponent! % (key.q! - BigInt.one));
    // Calculate q^(-1) mod p
    final qInv = ASN1Integer(_modInverse(key.q!, key.p!));

    final sequence = ASN1Sequence();
    sequence.add(version);
    sequence.add(modulus);
    sequence.add(publicExponent);
    sequence.add(privateExponent);
    sequence.add(p);
    sequence.add(q);
    sequence.add(dP);
    sequence.add(dQ);
    sequence.add(qInv);

    final bytes = sequence.encodedBytes;
    return '-----BEGIN RSA PRIVATE KEY-----\n${base64.encode(bytes).chunked(64)}\n-----END RSA PRIVATE KEY-----';
  }

  // Decode RSA private key from PEM
  static RSAPrivateKey _decodeRSAPrivateKeyFromPEM(String pem) {
    final bytes = base64.decode(pem
        .replaceFirst('-----BEGIN RSA PRIVATE KEY-----', '')
        .replaceFirst('-----END RSA PRIVATE KEY-----', '')
        .replaceAll('\n', '')
        .trim());

    final parser = ASN1Parser(bytes);
    final sequence = parser.nextObject() as ASN1Sequence;

    final modulus = (sequence.elements[1] as ASN1Integer).valueAsBigInteger;
    final publicExponent = (sequence.elements[2] as ASN1Integer).valueAsBigInteger;
    final privateExponent = (sequence.elements[3] as ASN1Integer).valueAsBigInteger;
    final p = (sequence.elements[4] as ASN1Integer).valueAsBigInteger;
    final q = (sequence.elements[5] as ASN1Integer).valueAsBigInteger;

    return RSAPrivateKey(
      modulus,
      publicExponent,
      privateExponent,
      p,
      q,
    );
  }

  // Encode RSA public key to PEM
  static String _encodeRSAPublicKeyToPEM(RSAPublicKey key) {
    // Create algorithm identifier for RSA
    final algorithmSequence = ASN1Sequence();
    algorithmSequence.add(ASN1ObjectIdentifier([1, 2, 840, 113549, 1, 1, 1])); // RSA OID
    algorithmSequence.add(ASN1Null());

    final publicKey = ASN1Sequence();
    publicKey.add(ASN1Integer(key.modulus!));
    publicKey.add(ASN1Integer(key.exponent!));

    final publicKeyBytes = publicKey.encodedBytes;
    final publicKeyBitString = ASN1BitString(publicKeyBytes);

    final sequence = ASN1Sequence();
    sequence.add(algorithmSequence);
    sequence.add(publicKeyBitString);

    final bytes = sequence.encodedBytes;
    return '-----BEGIN PUBLIC KEY-----\n${base64.encode(bytes).chunked(64)}\n-----END PUBLIC KEY-----';
  }

  // Decode RSA public key from PEM
  static RSAPublicKey _decodeRSAPublicKeyFromPEM(String pem) {
    final bytes = base64.decode(pem
        .replaceFirst('-----BEGIN PUBLIC KEY-----', '')
        .replaceFirst('-----END PUBLIC KEY-----', '')
        .replaceAll('\n', '')
        .trim());

    final parser = ASN1Parser(bytes);
    final outerSequence = parser.nextObject() as ASN1Sequence;

    // Skip algorithm identifier, get the bit string
    final bitString = outerSequence.elements[1] as ASN1BitString;

    final keyParser = ASN1Parser(Uint8List.fromList(bitString.stringValue));
    final publicKeySequence = keyParser.nextObject() as ASN1Sequence;

    final modulus = (publicKeySequence.elements[0] as ASN1Integer).valueAsBigInteger;
    final exponent = (publicKeySequence.elements[1] as ASN1Integer).valueAsBigInteger;

    return RSAPublicKey(modulus, exponent);
  }

  // Encrypt with RSA-OAEP
  static Uint8List _encryptWithRSA(Uint8List data, RSAPublicKey publicKey) {
    final encryptor = OAEPEncoding.withSHA256(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    return encryptor.process(data);
  }

  // Decrypt with RSA-OAEP
  static Uint8List _decryptWithRSA(Uint8List encryptedData, RSAPrivateKey privateKey) {
    final decryptor = OAEPEncoding.withSHA256(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return decryptor.process(encryptedData);
  }

  // Modular inverse for RSA CRT parameters
  static BigInt _modInverse(BigInt a, BigInt m) {
    if (a == BigInt.zero) return BigInt.zero;
    BigInt m0 = m;
    BigInt y = BigInt.zero;
    BigInt x = BigInt.one;

    if (m == BigInt.one) return BigInt.zero;

    while (a > BigInt.one) {
      BigInt q = a ~/ m;
      BigInt t = m;
      m = a % m;
      a = t;
      t = y;
      y = x - q * y;
      x = t;
    }

    if (x < BigInt.zero) x += m0;
    return x;
  }
}

// Extension for chunking strings
extension StringChunking on String {
  String chunked(int chunkSize) {
    final buffer = StringBuffer();
    for (int i = 0; i < length; i += chunkSize) {
      final end = (i + chunkSize < length) ? i + chunkSize : length;
      buffer.writeln(substring(i, end));
    }
    return buffer.toString().trimRight();
  }
}
