import 'package:cipher/cipher.dart';
import 'package:cipher/exception_message_constant.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String defaultPublicKey = 'PUBLIC_KEY';
  String defaultEncrptedValue = 'ENCRYPTED-XX';
  group(
    'Cipher',
    () {
      group(
        'when platform returns successfully',
        () {
          setUpAll(
            () {
              const MethodChannel('cipher').setMockMethodCallHandler(
                (MethodCall methodCall) async {
                  if (methodCall.method == 'getPublicKey') {
                    return Future.value(defaultPublicKey);
                  } else if (methodCall.method == 'encrypt' &&
                      methodCall.arguments != null) {
                    return Future.value(defaultEncrptedValue);
                  } else if (methodCall.method == 'verify') {
                    if (methodCall.arguments == null) {
                      throw Exception('Arguments cannot be empty');
                    }
                    return Future.value(true);
                  }
                },
              );
            },
          );

          test(
            'should return a valid public key when requested',
            () async {
              // when
              final String publicKey = await Cipher.getPublicKey();

              // then
              expect(publicKey, 'PUBLIC_KEY');
            },
          );

          test(
              'should return single line publicKey'
              ' when multi line key is returned', () async {
            // give
            defaultPublicKey = 'line1'
                'line2\nline3';
            expect(defaultPublicKey.contains('\n'), true);

            // when
            final String publicKey = await Cipher.getPublicKey();

            // then
            expect(publicKey, 'line1line2line3');
          });

          test(
            'should return a valid encrypted data from platform',
            () async {
              // when
              final String encrypted = await Cipher.encrypt('some  data');

              // then
              expect(encrypted, 'ENCRYPTED-XX');
            },
          );

          test(
            'should return single line value when multiline value is returned',
            () async {
              // given
              defaultEncrptedValue = 'encryptedLine1'
                  'encryptedLine2\nencryptedLine3';
              expect(defaultPublicKey.contains('\n'), true);

              // when
              final String encrypted = await Cipher.encrypt('some  data');

              // then
              expect(encrypted, 'encryptedLine1encryptedLine2encryptedLine3');
            },
          );
          test(
            'should return a bool after verifying from platform',
            () async {
              // when
              final bool result = await Cipher.verify('plain', 'signature');

              // then
              expect(result, true);
            },
          );
        },
      );

      group(
        'when platform throws excpetion',
        () {
          setUpAll(
            () {
              const MethodChannel('cipher').setMockMethodCallHandler(
                (MethodCall methodCall) async {
                  if (methodCall.method == 'getPublicKey') {
                    throw Exception('Error getting public key');
                  } else if (methodCall.method == 'encrypt') {
                    throw Exception('Error getting public key');
                  } else if (methodCall.method == 'verify') {
                    throw Exception('Error in verifying');
                  }
                },
              );
            },
          );

          test(
            'should throw exception when platform cannot return public key',
            () async {
              try {
                // when
                await Cipher.getPublicKey();
              } catch (exception) {
                // then
                expect(exception.runtimeType, PlatformException);
                expect(exception.code, 'CIPHER:GET_PUBLIC_KEY');
                expect(exception.message,
                    ExceptionMessageConstant.getPublicKeyFailed);
              }
            },
          );

          test(
            'should throw exception when platform cannot encrypt data',
            () async {
              try {
                // when
                await Cipher.encrypt(null);
              } catch (exception) {
                // then
                expect(exception.runtimeType, PlatformException);
                expect(exception.code, 'CIPHER:ENCRYPT');
                expect(exception.message,
                    ExceptionMessageConstant.encryptionFailed);
              }
            },
          );
          test(
            'should  throw exception when platform cannot verify signature',
            () async {
              try {
                // when
                await Cipher.verify('some', 'some');
              } catch (exception) {
                // then
                expect(exception.runtimeType, PlatformException);
                expect(exception.code, 'CIPHER:VERIFY');
                expect(exception.message,
                    ExceptionMessageConstant.verificationFailed);
              }
            },
          );
        },
      );
    },
  );
}