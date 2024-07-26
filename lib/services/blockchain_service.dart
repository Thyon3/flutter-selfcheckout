import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';

class BlockchainService {
  static final List<Block> _blockchain = [];
  static final Map<String, Transaction> _pendingTransactions = {};
  static final Map<String, Wallet> _wallets = {};
  static final Map<String, SmartContract> _contracts = {};
  
  static const String _genesisBlockHash = '0000000000000000000000000000000000000000000000000000000000000000';
  static const int _miningDifficulty = 4;
  static const double _miningReward = 10.0;
  
  static bool _isInitialized = false;
  static String? _currentMinerAddress;

  // Blockchain initialization
  static Future<void> initialize() async {
    try {
      if (_isInitialized) return;
      
      LoggingService.info('Initializing blockchain service');
      
      // Create genesis block
      final genesisBlock = Block(
        index: 0,
        timestamp: DateTime.now(),
        data: 'Genesis Block - ScanGo Blockchain',
        previousHash: _genesisBlockHash,
        nonce: 0,
        miner: 'genesis',
      );
      
      // Mine genesis block
      final minedGenesis = await _mineBlock(genesisBlock);
      _blockchain.add(minedGenesis);
      
      _isInitialized = true;
      
      LoggingService.info('Blockchain initialized with genesis block');
    } catch (e) {
      LoggingService.error('Failed to initialize blockchain: $e');
      rethrow;
    }
  }

  // Wallet management
  static Future<Wallet> createWallet({String? userId}) async {
    try {
      final privateKey = _generatePrivateKey();
      final publicKey = _generatePublicKey(privateKey);
      final address = _generateAddress(publicKey);
      
      final wallet = Wallet(
        address: address,
        publicKey: publicKey,
        privateKey: privateKey,
        userId: userId,
        balance: 0.0,
        createdAt: DateTime.now(),
      );
      
      _wallets[address] = wallet;
      
      LoggingService.info('Created wallet: $address');
      return wallet;
    } catch (e) {
      LoggingService.error('Failed to create wallet: $e');
      rethrow;
    }
  }

  static Wallet? getWallet(String address) {
    return _wallets[address];
  }

  static Future<double> getBalance(String address) async {
    final wallet = _wallets[address];
    if (wallet == null) return 0.0;
    
    double balance = wallet.balance;
    
    // Add pending transactions
    for (final transaction in _pendingTransactions.values) {
      if (transaction.toAddress == address && transaction.status == TransactionStatus.pending) {
        balance += transaction.amount;
      }
    }
    
    return balance;
  }

  // Transaction management
  static Future<String> createTransaction({
    required String fromAddress,
    required String toAddress,
    required double amount,
    String? data,
    double fee = 0.01,
  }) async {
    try {
      final fromWallet = _wallets[fromAddress];
      if (fromWallet == null) {
        throw Exception('Sender wallet not found: $fromAddress');
      }
      
      final balance = await getBalance(fromAddress);
      if (balance < amount + fee) {
        throw Exception('Insufficient balance');
      }
      
      final transaction = Transaction(
        id: _generateTransactionId(),
        fromAddress: fromAddress,
        toAddress: toAddress,
        amount: amount,
        fee: fee,
        data: data,
        timestamp: DateTime.now(),
        status: TransactionStatus.pending,
      );
      
      // Sign transaction
      transaction.signature = await _signTransaction(transaction, fromWallet.privateKey);
      
      // Add to pending transactions
      _pendingTransactions[transaction.id] = transaction;
      
      LoggingService.info('Created transaction: ${transaction.id}');
      return transaction.id;
    } catch (e) {
      LoggingService.error('Failed to create transaction: $e');
      rethrow;
    }
  }

  static Future<bool> validateTransaction(Transaction transaction) async {
    try {
      // Verify signature
      final fromWallet = _wallets[transaction.fromAddress];
      if (fromWallet == null) return false;
      
      final isValidSignature = await _verifySignature(
        transaction,
        transaction.signature!,
        fromWallet.publicKey,
      );
      
      if (!isValidSignature) return false;
      
      // Check balance
      final balance = await getBalance(transaction.fromAddress);
      if (balance < transaction.amount + transaction.fee) return false;
      
      // Check for double spending
      for (final block in _blockchain) {
        for (final tx in block.transactions) {
          if (tx.id == transaction.id) return false;
        }
      }
      
      return true;
    } catch (e) {
      LoggingService.error('Transaction validation failed: $e');
      return false;
    }
  }

  // Mining
  static Future<Block> mineBlock(String minerAddress) async {
    try {
      _currentMinerAddress = minerAddress;
      
      // Get pending transactions
      final validTransactions = <Transaction>[];
      
      for (final transaction in _pendingTransactions.values) {
        if (await validateTransaction(transaction)) {
          validTransactions.add(transaction);
        }
      }
      
      // Limit transactions per block
      if (validTransactions.length > 10) {
        validTransactions.length = 10;
      }
      
      // Create coinbase transaction
      final coinbase = Transaction(
        id: _generateTransactionId(),
        fromAddress: 'coinbase',
        toAddress: minerAddress,
        amount: _miningReward,
        fee: 0.0,
        timestamp: DateTime.now(),
        status: TransactionStatus.confirmed,
      );
      
      validTransactions.insert(0, coinbase);
      
      // Create new block
      final previousBlock = _blockchain.last;
      final newBlock = Block(
        index: previousBlock.index + 1,
        timestamp: DateTime.now(),
        data: json.encode(validTransactions.map((tx) => tx.toJson()).toList()),
        previousHash: previousBlock.hash,
        nonce: 0,
        miner: minerAddress,
        transactions: validTransactions,
      );
      
      // Mine the block
      final minedBlock = await _mineBlock(newBlock);
      
      // Add to blockchain
      _blockchain.add(minedBlock);
      
      // Update wallet balances
      for (final transaction in validTransactions) {
        if (transaction.status == TransactionStatus.pending) {
          transaction.status = TransactionStatus.confirmed;
          _pendingTransactions.remove(transaction.id);
          
          // Update balances
          final fromWallet = _wallets[transaction.fromAddress];
          final toWallet = _wallets[transaction.toAddress];
          
          if (fromWallet != null && transaction.fromAddress != 'coinbase') {
            fromWallet.balance -= transaction.amount + transaction.fee;
          }
          
          if (toWallet != null) {
            toWallet.balance += transaction.amount;
          }
        }
      }
      
      LoggingService.info('Mined block: ${minedBlock.hash}');
      return minedBlock;
    } catch (e) {
      LoggingService.error('Mining failed: $e');
      rethrow;
    }
  }

  static Future<Block> _mineBlock(Block block) async {
    String hash;
    int nonce = 0;
    
    do {
      nonce++;
      hash = _calculateBlockHash(block.copyWith(nonce: nonce));
    } while (!hash.startsWith('0' * _miningDifficulty));
    
    return block.copyWith(
      nonce: nonce,
      hash: hash,
    );
  }

  // Smart contracts
  static Future<String> deployContract({
    required String ownerAddress,
    required String code,
    required String abi,
    Map<String, dynamic>? constructorArgs,
  }) async {
    try {
      final contractId = _generateContractId();
      
      final contract = SmartContract(
        id: contractId,
        ownerAddress: ownerAddress,
        code: code,
        abi: abi,
        state: {},
        deployedAt: DateTime.now(),
        constructorArgs: constructorArgs ?? {},
      );
      
      _contracts[contractId] = contract;
      
      LoggingService.info('Deployed smart contract: $contractId');
      return contractId;
    } catch (e) {
      LoggingService.error('Failed to deploy contract: $e');
      rethrow;
    }
  }

  static Future<dynamic> callContract({
    required String contractId,
    required String functionName,
    required List<dynamic> args,
    String? callerAddress,
  }) async {
    try {
      final contract = _contracts[contractId];
      if (contract == null) {
        throw Exception('Contract not found: $contractId');
      }
      
      // Mock contract execution
      final result = await _executeContractFunction(contract, functionName, args, callerAddress);
      
      LoggingService.info('Called contract function: $contractId.$functionName');
      return result;
    } catch (e) {
      LoggingService.error('Contract call failed: $e');
      rethrow;
    }
  }

  static Future<dynamic> _executeContractFunction(
    SmartContract contract,
    String functionName,
    List<dynamic> args,
    String? callerAddress,
  ) async {
    // Mock contract execution
    switch (functionName) {
      case 'balanceOf':
        return contract.state['balances'][args[0]] ?? 0;
      case 'transfer':
        final from = callerAddress;
        final to = args[0];
        final amount = args[1];
        
        final fromBalance = contract.state['balances'][from] ?? 0;
        if (fromBalance < amount) {
          throw Exception('Insufficient balance');
        }
        
        contract.state['balances'][from] = fromBalance - amount;
        contract.state['balances'][to] = (contract.state['balances'][to] ?? 0) + amount;
        
        return true;
      case 'approve':
        final spender = args[0];
        final amount = args[1];
        contract.state['allowances'][callerAddress] = {
          ...contract.state['allowances'][callerAddress] ?? {},
          spender: amount,
        };
        return true;
      case 'totalSupply':
        return contract.state['totalSupply'] ?? 0;
      default:
        throw Exception('Unknown function: $functionName');
    }
  }

  // Supply chain tracking
  static Future<String> createSupplyChainItem({
    required String productId,
    required String name,
    required String description,
    required String manufacturerAddress,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final itemId = _generateItemId();
      
      final transaction = await createTransaction(
        fromAddress: manufacturerAddress,
        toAddress: 'supply_chain',
        amount: 0.0,
        data: json.encode({
          'type': 'create_item',
          'item_id': itemId,
          'product_id': productId,
          'name': name,
          'description': description,
          'metadata': metadata ?? {},
        }),
      );
      
      LoggingService.info('Created supply chain item: $itemId');
      return itemId;
    } catch (e) {
      LoggingService.error('Failed to create supply chain item: $e');
      rethrow;
    }
  }

  static Future<String> transferSupplyChainItem({
    required String itemId,
    required String fromAddress,
    required String toAddress,
    String? location,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final transaction = await createTransaction(
        fromAddress: fromAddress,
        toAddress: toAddress,
        amount: 0.0,
        data: json.encode({
          'type': 'transfer_item',
          'item_id': itemId,
          'location': location,
          'metadata': metadata ?? {},
        }),
      );
      
      LoggingService.info('Transferred supply chain item: $itemId');
      return transaction;
    } catch (e) {
      LoggingService.error('Failed to transfer supply chain item: $e');
      rethrow;
    }
  }

  static Future<List<SupplyChainEvent>> getSupplyChainHistory(String itemId) async {
    final events = <SupplyChainEvent>[];
    
    for (final block in _blockchain) {
      for (final transaction in block.transactions) {
        if (transaction.data != null) {
          try {
            final data = json.decode(transaction.data!);
            if (data['type'] == 'create_item' && data['item_id'] == itemId) {
              events.add(SupplyChainEvent(
                type: 'created',
                itemId: itemId,
                transactionId: transaction.id,
                timestamp: transaction.timestamp,
                data: data,
              ));
            } else if (data['type'] == 'transfer_item' && data['item_id'] == itemId) {
              events.add(SupplyChainEvent(
                type: 'transferred',
                itemId: itemId,
                transactionId: transaction.id,
                timestamp: transaction.timestamp,
                fromAddress: transaction.fromAddress,
                toAddress: transaction.toAddress,
                data: data,
              ));
            }
          } catch (e) {
            // Skip invalid data
          }
        }
      }
    }
    
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return events;
  }

  // Utility methods
  static String _generatePrivateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _generatePublicKey(String privateKey) {
    // Mock public key generation
    final hash = sha256.convert(utf8.encode(privateKey));
    return hash.toString();
  }

  static String _generateAddress(String publicKey) {
    // Mock address generation
    final hash = sha256.convert(utf8.encode(publicKey));
    return '0x${hash.toString().substring(0, 40)}';
  }

  static String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000000);
    return 'tx_${timestamp}_$random';
  }

  static String _generateContractId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000000);
    return 'contract_${timestamp}_$random';
  }

  static String _generateItemId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000000);
    return 'item_${timestamp}_$random';
  }

  static String _calculateBlockHash(Block block) {
    final data = '${block.index}${block.timestamp}${block.data}${block.previousHash}${block.nonce}';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<String> _signTransaction(Transaction transaction, String privateKey) async {
    final data = '${transaction.id}${transaction.fromAddress}${transaction.toAddress}${transaction.amount}${transaction.fee}${transaction.timestamp}';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    
    // Mock signature
    return '0x${digest.toString()}${privateKey.substring(0, 16)}';
  }

  static Future<bool> _verifySignature(
    Transaction transaction,
    String signature,
    String publicKey,
  ) async {
    // Mock signature verification
    final expectedSignature = await _signTransaction(transaction, privateKey: publicKey);
    return signature == expectedSignature;
  }

  // Getters
  static List<Block> get blockchain => List.from(_blockchain);
  static Block? get latestBlock => _blockchain.isNotEmpty ? _blockchain.last : null;
  static List<Transaction> get pendingTransactions => _pendingTransactions.values.toList();
  static List<Wallet> get wallets => _wallets.values.toList();
  static List<SmartContract> get contracts => _contracts.values.toList();
  static bool get isInitialized => _isInitialized;
  static int get difficulty => _miningDifficulty;
  static double get miningReward => _miningReward;
}

// Data models
class Block {
  final int index;
  final DateTime timestamp;
  final String data;
  final String previousHash;
  final String hash;
  final int nonce;
  final String miner;
  final List<Transaction>? transactions;

  Block({
    required this.index,
    required this.timestamp,
    required this.data,
    required this.previousHash,
    required this.hash,
    required this.nonce,
    required this.miner,
    this.transactions,
  });

  Block copyWith({
    int? index,
    DateTime? timestamp,
    String? data,
    String? previousHash,
    String? hash,
    int? nonce,
    String? miner,
    List<Transaction>? transactions,
  }) {
    return Block(
      index: index ?? this.index,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      previousHash: previousHash ?? this.previousHash,
      hash: hash ?? this.hash,
      nonce: nonce ?? this.nonce,
      miner: miner ?? this.miner,
      transactions: transactions ?? this.transactions,
    );
  }
}

class Transaction {
  final String id;
  final String fromAddress;
  final String toAddress;
  final double amount;
  final double fee;
  final String? data;
  final DateTime timestamp;
  TransactionStatus status;
  String? signature;

  Transaction({
    required this.id,
    required this.fromAddress,
    required this.toAddress,
    required this.amount,
    required this.fee,
    this.data,
    required this.timestamp,
    required this.status,
    this.signature,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_address': fromAddress,
      'to_address': toAddress,
      'amount': amount,
      'fee': fee,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'signature': signature,
    };
  }
}

class Wallet {
  final String address;
  final String publicKey;
  final String privateKey;
  final String? userId;
  double balance;
  final DateTime createdAt;

  Wallet({
    required this.address,
    required this.publicKey,
    required this.privateKey,
    this.userId,
    required this.balance,
    required this.createdAt,
  });
}

class SmartContract {
  final String id;
  final String ownerAddress;
  final String code;
  final String abi;
  Map<String, dynamic> state;
  final DateTime deployedAt;
  final Map<String, dynamic> constructorArgs;

  SmartContract({
    required this.id,
    required this.ownerAddress,
    required this.code,
    required this.abi,
    required this.state,
    required this.deployedAt,
    required this.constructorArgs,
  });
}

class SupplyChainEvent {
  final String type;
  final String itemId;
  final String transactionId;
  final DateTime timestamp;
  final String? fromAddress;
  final String? toAddress;
  final Map<String, dynamic> data;

  SupplyChainEvent({
    required this.type,
    required this.itemId,
    required this.transactionId,
    required this.timestamp,
    this.fromAddress,
    this.toAddress,
    required this.data,
  });
}

enum TransactionStatus {
  pending,
  confirmed,
  failed,
}
