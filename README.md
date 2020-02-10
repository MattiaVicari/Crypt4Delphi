# Crypt4Delphi Overview
Cryptography library for Delphi

The purpose of this project is to provide a library for help the Delphi developers to use cryptography.

## List of demos:
* 01 CNG AES: demo for AES using Cryptography Next Generation.
* 02 CNG RNG demo for generating random buffer using CNG API.
* 03 CNG Sign demo for sign and verify with RSA using CNG e Crypto API.
In order to run this demo, you have to have openssl installed to generate the key pair (see batch file in data folder). If you already have a key pair, you can copy them in the data folder of the demo and rename them in keypair.pem for privaty key and pubkey.pem for public key.

## About CNG
CNG means for Cryptography API Next Generation. For more information about the API, please visit the page https://docs.microsoft.com/en-us/windows/win32/seccng/cng-portal.

## Test
In the folder Tests there is the group of projects for tests. 

In order to get the test projects work, you have to install the [DUnitX](https://github.com/VSoftTechnologies/DUnitX) library.