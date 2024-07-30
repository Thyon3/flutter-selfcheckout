import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/cache_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';

class BlockchainSupplyChainService {
  static const String _baseUrl = 'https://api.blockchain.scango.app';
  static const String _wsUrl = 'wss://blockchain.scango.app/ws';
  static const String _apiKey = 'blockchain_api_key_12345';
  static const String _cacheKey = 'blockchain_supply_chain_cache';
  
  static bool _isInitialized = false;
  static bool _isConnected = false;
  static WebSocketChannel? _blockchainChannel;
  static StreamSubscription? _blockchainSubscription;
  static Blockchain? _currentBlockchain;
  static final List<SupplyChainNode> _nodes = [];
  static final List<ProductBatch> _productBatches = [];
  static final List<SupplyChainTransaction> _transactions = [];
  static StreamController<BlockchainEvent>? _eventController;

  // Blockchain supply chain service initialization
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing blockchain supply chain service');
      
      // Initialize event controller
      _eventController = StreamController<BlockchainEvent>.broadcast();
      
      // Connect to blockchain network
      await _connectToBlockchain();
      
      // Initialize blockchain
      await _initializeBlockchain();
      
      // Load nodes
      await _loadNodes();
      
      // Load product batches
      await _loadProductBatches();
      
      // Load transactions
      await _loadTransactions();
      
      _isInitialized = true;
      
      LoggingService.info('Blockchain supply chain service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize blockchain supply chain service: $e');
      return false;
    }
  }

  // Blockchain network connection
  static Future<void> _connectToBlockchain() async {
    try {
      _blockchainChannel = WebSocketChannel.connect(Uri.parse('$_wsUrl/network'));
      
      // Authenticate
      final authMessage = {
        'type': 'auth',
        'api_key': _apiKey,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _blockchainChannel!.sink.add(json.encode(authMessage));
      
      // Listen for blockchain events
      _blockchainSubscription = _blockchainChannel!.stream.listen(
        _handleBlockchainEvent,
        onError: _handleBlockchainError,
        onDone: _handleBlockchainDisconnect,
      );
      
      _isConnected = true;
      
      LoggingService.info('Connected to blockchain network');
    } catch (e) {
      LoggingService.error('Failed to connect to blockchain: $e');
      _isConnected = false;
    }
  }

  // Blockchain management
  static Future<void> _initializeBlockchain() async {
    try {
      // Mock blockchain initialization
      await Future.delayed(Duration(seconds: 2));
      
      _currentBlockchain = Blockchain(
        id: 'scango_supply_chain',
        name: 'ScanGo Supply Chain',
        network: 'ethereum',
        blockHeight: 12345,
        consensusAlgorithm: 'proof_of_authority',
        nodes: [],
        createdAt: DateTime.now().subtract(Duration(days: 365)),
        lastBlockTime: DateTime.now(),
      );
      
      LoggingService.info('Blockchain initialized: ${_currentBlockchain!.id}');
    } catch (e) {
      LoggingService.error('Failed to initialize blockchain: $e');
    }
  }

  // Supply chain node management
  static Future<SupplyChainNodeResult> addNode({
    required String nodeId,
    required String nodeName,
    required NodeType nodeType,
    required String organization,
    required String location,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      // Create node
      final node = SupplyChainNode(
        id: nodeId,
        name: nodeName,
        type: nodeType,
        organization: organization,
        location: location,
        blockchainAddress: _generateBlockchainAddress(),
        status: NodeStatus.active,
        metadata: metadata ?? {},
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        reputationScore: 100.0,
        verifiedTransactions: 0,
      );
      
      // Register node on blockchain
      await _registerNodeOnBlockchain(node);
      
      _nodes.add(node);
      
      // Emit node added event
      _emitEvent(BlockchainEvent(
        type: BlockchainEventType.nodeAdded,
        data: node.toJson(),
      ));
      
      LoggingService.info('Supply chain node added: $nodeId');
      return SupplyChainNodeResult(
        success: true,
        node: node,
      );
    } catch (e) {
      LoggingService.error('Failed to add supply chain node: $e');
      return SupplyChainNodeResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _registerNodeOnBlockchain(SupplyChainNode node) async {
    try {
      final registration = {
        'type': 'register_node',
        'node_id': node.id,
        'node_name': node.name,
        'node_type': node.type.name,
        'organization': node.organization,
        'location': node.location,
        'blockchain_address': node.blockchainAddress,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _blockchainChannel?.sink.add(json.encode(registration));
      
      LoggingService.info('Node registered on blockchain: ${node.id}');
    } catch (e) {
      LoggingService.error('Failed to register node on blockchain: $e');
    }
  }

  // Product batch management
  static Future<ProductBatchResult> createProductBatch({
    required String batchId,
    required String productId,
    required String productName,
    required String manufacturerId,
    required int quantity,
    required DateTime productionDate,
    required DateTime expiryDate,
    Map<String, dynamic>? batchDetails,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      // Create product batch
      final batch = ProductBatch(
        id: batchId,
        productId: productId,
        productName: productName,
        manufacturerId: manufacturerId,
        quantity: quantity,
        productionDate: productionDate,
        expiryDate: expiryDate,
        currentLocation: manufacturerId,
        status: BatchStatus.created,
        blockchainTokenId: _generateTokenId(),
        qualityChecks: [],
        transactions: [],
        metadata: batchDetails ?? {},
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      
      // Mint batch token on blockchain
      await _mintBatchToken(batch);
      
      _productBatches.add(batch);
      
      // Create initial transaction
      await _createTransaction(
        batchId: batchId,
        transactionType: TransactionType.creation,
        fromNodeId: manufacturerId,
        toNodeId: manufacturerId,
        metadata: {
          'action': 'batch_creation',
          'quantity': quantity,
          'production_date': productionDate.toIso8601String(),
        },
      );
      
      // Emit batch created event
      _emitEvent(BlockchainEvent(
        type: BlockchainEventType.batchCreated,
        data: batch.toJson(),
      ));
      
      LoggingService.info('Product batch created: $batchId');
      return ProductBatchResult(
        success: true,
        batch: batch,
      );
    } catch (e) {
      LoggingService.error('Failed to create product batch: $e');
      return ProductBatchResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _mintBatchToken(ProductBatch batch) async {
    try {
      final minting = {
        'type': 'mint_token',
        'batch_id': batch.id,
        'product_id': batch.productId,
        'token_id': batch.blockchainTokenId,
        'quantity': batch.quantity,
        'metadata': {
          'product_name': batch.productName,
          'production_date': batch.productionDate.toIso8601String(),
          'expiry_date': batch.expiryDate.toIso8601String(),
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _blockchainChannel?.sink.add(json.encode(minting));
      
      LoggingService.info('Batch token minted: ${batch.blockchainTokenId}');
    } catch (e) {
      LoggingService.error('Failed to mint batch token: $e');
    }
  }

  // Supply chain transactions
  static Future<TransactionResult> transferProduct({
    required String batchId,
    required String fromNodeId,
    required String toNodeId,
    required int quantity,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      final batch = _productBatches.firstWhere(
        (b) => b.id == batchId,
        orElse: () => throw Exception('Product batch not found: $batchId'),
      );
      
      // Validate transfer
      if (batch.quantity < quantity) {
        return TransactionResult(
          success: false,
          error: 'Insufficient quantity in batch',
        );
      }
      
      // Create transaction
      final transaction = await _createTransaction(
        batchId: batchId,
        transactionType: TransactionType.transfer,
        fromNodeId: fromNodeId,
        toNodeId: toNodeId,
        quantity: quantity,
        reason: reason,
        metadata: metadata,
      );
      
      // Update batch
      batch.quantity -= quantity;
      batch.currentLocation = toNodeId;
      batch.lastUpdated = DateTime.now();
      batch.transactions.add(transaction.id);
      
      // Update blockchain token
      await _updateTokenOwnership(batch, toNodeId, quantity);
      
      // Emit transfer event
      _emitEvent(BlockchainEvent(
        type: BlockchainEventType.productTransferred,
        data: {
          'batch_id': batchId,
          'transaction_id': transaction.id,
          'from_node': fromNodeId,
          'to_node': toNodeId,
          'quantity': quantity,
        },
      ));
      
      LoggingService.info('Product transferred: $batchId ($quantity units from $fromNodeId to $toNodeId)');
      return TransactionResult(
        success: true,
        transaction: transaction,
      );
    } catch (e) {
      LoggingService.error('Failed to transfer product: $e');
      return TransactionResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<SupplyChainTransaction> _createTransaction({
    required String batchId,
    required TransactionType transactionType,
    required String fromNodeId,
    required String toNodeId,
    int quantity = 0,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final transaction = SupplyChainTransaction(
        id: _generateTransactionId(),
        batchId: batchId,
        type: transactionType,
        fromNodeId: fromNodeId,
        toNodeId: toNodeId,
        quantity: quantity,
        reason: reason,
        metadata: metadata ?? {},
        timestamp: DateTime.now(),
        blockchainHash: _generateBlockchainHash(),
        verified: false,
        verifications: [],
      );
      
      // Submit transaction to blockchain
      await _submitTransactionToBlockchain(transaction);
      
      _transactions.add(transaction);
      
      return transaction;
    } catch (e) {
      LoggingService.error('Failed to create transaction: $e');
      rethrow;
    }
  }

  static Future<void> _submitTransactionToBlockchain(SupplyChainTransaction transaction) async {
    try {
      final submission = {
        'type': 'submit_transaction',
        'transaction_id': transaction.id,
        'batch_id': transaction.batchId,
        'transaction_type': transaction.type.name,
        'from_node': transaction.fromNodeId,
        'to_node': transaction.toNodeId,
        'quantity': transaction.quantity,
        'reason': transaction.reason,
        'metadata': transaction.metadata,
        'timestamp': transaction.timestamp.toIso8601String(),
      };
      
      _blockchainChannel?.sink.add(json.encode(submission));
      
      LoggingService.info('Transaction submitted to blockchain: ${transaction.id}');
    } catch (e) {
      LoggingService.error('Failed to submit transaction to blockchain: $e');
    }
  }

  static Future<void> _updateTokenOwnership(ProductBatch batch, String newOwner, int quantity) async {
    try {
      final update = {
        'type': 'update_token_ownership',
        'batch_id': batch.id,
        'token_id': batch.blockchainTokenId,
        'new_owner': newOwner,
        'quantity': quantity,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _blockchainChannel?.sink.add(json.encode(update));
      
      LoggingService.info('Token ownership updated: ${batch.blockchainTokenId}');
    } catch (e) {
      LoggingService.error('Failed to update token ownership: $e');
    }
  }

  // Quality checks and certifications
  static Future<QualityCheckResult> addQualityCheck({
    required String batchId,
    required String nodeId,
    required QualityCheckType checkType,
    required bool passed,
    required String inspectorId,
    String? notes,
    Map<String, dynamic>? checkData,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      final batch = _productBatches.firstWhere(
        (b) => b.id == batchId,
        orElse: () => throw Exception('Product batch not found: $batchId'),
      );
      
      // Create quality check
      final qualityCheck = QualityCheck(
        id: _generateQualityCheckId(),
        batchId: batchId,
        nodeId: nodeId,
        checkType: checkType,
        passed: passed,
        inspectorId: inspectorId,
        notes: notes,
        checkData: checkData ?? {},
        timestamp: DateTime.now(),
        blockchainHash: _generateBlockchainHash(),
        verified: false,
      );
      
      batch.qualityChecks.add(qualityCheck);
      
      // Submit quality check to blockchain
      await _submitQualityCheckToBlockchain(qualityCheck);
      
      // Create transaction
      await _createTransaction(
        batchId: batchId,
        transactionType: TransactionType.quality_check,
        fromNodeId: nodeId,
        toNodeId: nodeId,
        metadata: {
          'quality_check_id': qualityCheck.id,
          'check_type': checkType.name,
          'passed': passed,
          'inspector_id': inspectorId,
        },
      );
      
      // Emit quality check event
      _emitEvent(BlockchainEvent(
        type: BlockchainEventType.qualityCheckAdded,
        data: qualityCheck.toJson(),
      ));
      
      LoggingService.info('Quality check added: ${qualityCheck.id}');
      return QualityCheckResult(
        success: true,
        qualityCheck: qualityCheck,
      );
    } catch (e) {
      LoggingService.error('Failed to add quality check: $e');
      return QualityCheckResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _submitQualityCheckToBlockchain(QualityCheck qualityCheck) async {
    try {
      final submission = {
        'type': 'submit_quality_check',
        'check_id': qualityCheck.id,
        'batch_id': qualityCheck.batchId,
        'node_id': qualityCheck.nodeId,
        'check_type': qualityCheck.checkType.name,
        'passed': qualityCheck.passed,
        'inspector_id': qualityCheck.inspectorId,
        'notes': qualityCheck.notes,
        'check_data': qualityCheck.checkData,
        'timestamp': qualityCheck.timestamp.toIso8601String(),
      };
      
      _blockchainChannel?.sink.add(json.encode(submission));
      
      LoggingService.info('Quality check submitted to blockchain: ${qualityCheck.id}');
    } catch (e) {
      LoggingService.error('Failed to submit quality check to blockchain: $e');
    }
  }

  // Product tracking and verification
  static Future<ProductTrackingResult> trackProduct({
    required String batchId,
    required String tokenId,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      final batch = _productBatches.firstWhere(
        (b) => b.id == batchId,
        orElse: () => throw Exception('Product batch not found: $batchId'),
      );
      
      // Get transaction history
      final batchTransactions = _transactions
          .where((t) => t.batchId == batchId)
          .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Get quality check history
      final qualityChecks = batch.qualityChecks
          .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Calculate supply chain path
      final supplyChainPath = _calculateSupplyChainPath(batchTransactions);
      
      // Verify authenticity
      final isAuthentic = await _verifyProductAuthenticity(batch, tokenId);
      
      return ProductTrackingResult(
        success: true,
        batch: batch,
        transactions: batchTransactions,
        qualityChecks: qualityChecks,
        supplyChainPath: supplyChainPath,
        isAuthentic: isAuthentic,
      );
    } catch (e) {
      LoggingService.error('Failed to track product: $e');
      return ProductTrackingResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static List<SupplyChainStep> _calculateSupplyChainPath(List<SupplyChainTransaction> transactions) {
    final steps = <SupplyChainStep>[];
    
    for (final transaction in transactions) {
      final step = SupplyChainStep(
        transactionId: transaction.id,
        nodeId: transaction.toNodeId,
        timestamp: transaction.timestamp,
        transactionType: transaction.type,
        metadata: transaction.metadata,
      );
      
      steps.add(step);
    }
    
    return steps;
  }

  static Future<bool> _verifyProductAuthenticity(ProductBatch batch, String tokenId) async {
    try {
      // Mock verification - check if token matches batch
      if (batch.blockchainTokenId == tokenId) {
        return true;
      }
      
      // Additional verification checks
      final hasValidQualityChecks = batch.qualityChecks.any((qc) => qc.passed);
      final hasValidTransactions = batch.transactions.isNotEmpty;
      
      return hasValidQualityChecks && hasValidTransactions;
    } catch (e) {
      LoggingService.error('Failed to verify product authenticity: $e');
      return false;
    }
  }

  // Smart contracts
  static Future<SmartContractResult> deploySmartContract({
    required String contractId,
    required String contractName,
    required String contractCode,
    required String deployerNodeId,
    Map<String, dynamic>? constructorArgs,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      // Create smart contract
      final contract = SmartContract(
        id: contractId,
        name: contractName,
        code: contractCode,
        deployerNodeId: deployerNodeId,
        constructorArgs: constructorArgs ?? {},
        blockchainAddress: _generateBlockchainAddress(),
        status: ContractStatus.deployed,
        deployedAt: DateTime.now(),
        functions: [],
        events: [],
      );
      
      // Deploy contract on blockchain
      await _deploySmartContractOnBlockchain(contract);
      
      // Emit contract deployed event
      _emitEvent(BlockchainEvent(
        type: BlockchainEventType.smartContractDeployed,
        data: contract.toJson(),
      ));
      
      LoggingService.info('Smart contract deployed: $contractId');
      return SmartContractResult(
        success: true,
        contract: contract,
      );
    } catch (e) {
      LoggingService.error('Failed to deploy smart contract: $e');
      return SmartContractResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _deploySmartContractOnBlockchain(SmartContract contract) async {
    try {
      final deployment = {
        'type': 'deploy_contract',
        'contract_id': contract.id,
        'contract_name': contract.name,
        'contract_code': contract.code,
        'deployer_node': contract.deployerNodeId,
        'constructor_args': contract.constructorArgs,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _blockchainChannel?.sink.add(json.encode(deployment));
      
      LoggingService.info('Smart contract deployed on blockchain: ${contract.id}');
    } catch (e) {
      LoggingService.error('Failed to deploy smart contract on blockchain: $e');
    }
  }

  // Analytics and reporting
  static Future<SupplyChainAnalytics> getAnalytics({
    DateTime? startDate,
    DateTime? endDate,
    String? nodeId,
  }) async {
    try {
      var transactions = List<SupplyChainTransaction>.from(_transactions);
      var batches = List<ProductBatch>.from(_productBatches);
      
      if (startDate != null) {
        transactions = transactions.where((t) => t.timestamp.isAfter(startDate)).toList();
        batches = batches.where((b) => b.createdAt.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        transactions = transactions.where((t) => t.timestamp.isBefore(endDate)).toList();
        batches = batches.where((b) => b.createdAt.isBefore(endDate)).toList();
      }
      
      if (nodeId != null) {
        transactions = transactions.where((t) => 
            t.fromNodeId == nodeId || t.toNodeId == nodeId).toList();
        batches = batches.where((b) => b.currentLocation == nodeId).toList();
      }
      
      final transactionTypeStats = <TransactionType, int>{};
      final nodeActivityStats = <String, int>{};
      final qualityCheckStats = <QualityCheckType, Map<String, int>>{};
      
      for (final transaction in transactions) {
        transactionTypeStats[transaction.type] = (transactionTypeStats[transaction.type] ?? 0) + 1;
        nodeActivityStats[transaction.fromNodeId] = (nodeActivityStats[transaction.fromNodeId] ?? 0) + 1;
        nodeActivityStats[transaction.toNodeId] = (nodeActivityStats[transaction.toNodeId] ?? 0) + 1;
      }
      
      for (final batch in batches) {
        for (final qualityCheck in batch.qualityChecks) {
          qualityCheckStats[qualityCheck.checkType] = qualityCheckStats[qualityCheck.checkType] ?? {};
          final status = qualityCheck.passed ? 'passed' : 'failed';
          qualityCheckStats[qualityCheck.checkType]![status] = (qualityCheckStats[qualityCheck.checkType]![status] ?? 0) + 1;
        }
      }
      
      return SupplyChainAnalytics(
        totalTransactions: transactions.length,
        totalBatches: batches.length,
        transactionTypeStats: transactionTypeStats,
        nodeActivityStats: nodeActivityStats,
        qualityCheckStats: qualityCheckStats,
        startDate: startDate ?? DateTime.now().subtract(Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Failed to get supply chain analytics: $e');
      return SupplyChainAnalytics(
        totalTransactions: 0,
        totalBatches: 0,
        transactionTypeStats: {},
        nodeActivityStats: {},
        qualityCheckStats: {},
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );
    }
  }

  // Event handlers
  static void _handleBlockchainEvent(dynamic event) {
    try {
      final data = json.decode(event);
      final eventType = data['type'];
      
      switch (eventType) {
        case 'transaction_confirmed':
          _handleTransactionConfirmed(data);
          break;
        case 'quality_check_verified':
          _handleQualityCheckVerified(data);
          break;
        case 'smart_contract_executed':
          _handleSmartContractExecuted(data);
          break;
        case 'node_status_updated':
          _handleNodeStatusUpdated(data);
          break;
      }
    } catch (e) {
      LoggingService.error('Failed to handle blockchain event: $e');
    }
  }

  static void _handleTransactionConfirmed(Map<String, dynamic> data) {
    try {
      final transactionId = data['transaction_id'];
      final transaction = _transactions.firstWhere(
        (t) => t.id == transactionId,
        orElse: () => null,
      );
      
      if (transaction != null) {
        transaction.verified = true;
        transaction.verifiedAt = DateTime.now();
        
        _emitEvent(BlockchainEvent(
          type: BlockchainEventType.transactionConfirmed,
          data: transaction.toJson(),
        ));
      }
    } catch (e) {
      LoggingService.error('Failed to handle transaction confirmed: $e');
    }
  }

  static void _handleQualityCheckVerified(Map<String, dynamic> data) {
    try {
      final checkId = data['check_id'];
      
      for (final batch in _productBatches) {
        final qualityCheck = batch.qualityChecks.firstWhere(
          (qc) => qc.id == checkId,
          orElse: () => null,
        );
        
        if (qualityCheck != null) {
          qualityCheck.verified = true;
          qualityCheck.verifiedAt = DateTime.now();
          
          _emitEvent(BlockchainEvent(
            type: BlockchainEventType.qualityCheckVerified,
            data: qualityCheck.toJson(),
          ));
          break;
        }
      }
    } catch (e) {
      LoggingService.error('Failed to handle quality check verified: $e');
    }
  }

  static void _handleSmartContractExecuted(Map<String, dynamic> data) {
    try {
      _emitEvent(BlockchainEvent(
        type: BlockchainEventType.smartContractExecuted,
        data: data,
      ));
    } catch (e) {
      LoggingService.error('Failed to handle smart contract executed: $e');
    }
  }

  static void _handleNodeStatusUpdated(Map<String, dynamic> data) {
    try {
      final nodeId = data['node_id'];
      final node = _nodes.firstWhere(
        (n) => n.id == nodeId,
        orElse: () => null,
      );
      
      if (node != null) {
        node.status = NodeStatus.values.firstWhere(
          (s) => s.name == data['status'],
          orElse: () => NodeStatus.active,
        );
        node.lastActive = DateTime.now();
        
        _emitEvent(BlockchainEvent(
          type: BlockchainEventType.nodeStatusUpdated,
          data: node.toJson(),
        ));
      }
    } catch (e) {
      LoggingService.error('Failed to handle node status updated: $e');
    }
  }

  static void _handleBlockchainError(dynamic error) {
    LoggingService.error('Blockchain service error: $error');
    _emitEvent(BlockchainEvent(
      type: BlockchainEventType.error,
      data: {'error': error.toString()},
    ));
  }

  static void _handleBlockchainDisconnect() {
    LoggingService.info('Blockchain service disconnected');
    _isConnected = false;
    _emitEvent(BlockchainEvent(
      type: BlockchainEventType.serviceDisconnected,
      data: {},
    ));
  }

  static void _emitEvent(BlockchainEvent event) {
    _eventController?.add(event);
  }

  // Utility methods
  static String _generateBlockchainAddress() {
    final chars = '0123456789abcdef';
    return '0x' + List.generate(40, (_) => chars[Random().nextInt(chars.length)]).join();
  }

  static String _generateTokenId() {
    return 'token_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateTransactionId() {
    return 'tx_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateQualityCheckId() {
    return 'qc_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateBlockchainHash() {
    final chars = '0123456789abcdef';
    return List.generate(64, (_) => chars[Random().nextInt(chars.length)]).join();
  }

  // Data loading methods
  static Future<void> _loadNodes() async {
    try {
      // Mock loading nodes
      _nodes.addAll([
        SupplyChainNode(
          id: 'manufacturer_001',
          name: 'ScanGo Manufacturing',
          type: NodeType.manufacturer,
          organization: 'ScanGo Corp',
          location: 'Colombo, Sri Lanka',
          blockchainAddress: '0x1234567890abcdef1234567890abcdef12345678',
          status: NodeStatus.active,
          metadata: {'certifications': ['ISO 9001', 'GMP']},
          createdAt: DateTime.now().subtract(Duration(days: 365)),
          lastActive: DateTime.now(),
          reputationScore: 98.5,
          verifiedTransactions: 1250,
        ),
        SupplyChainNode(
          id: 'distributor_001',
          name: 'ScanGo Distribution',
          type: NodeType.distributor,
          organization: 'ScanGo Logistics',
          location: 'Maharagama, Sri Lanka',
          blockchainAddress: '0x2345678901bcdef2345678901bcdef23456789',
          status: NodeStatus.active,
          metadata: {'coverage': 'nationwide'},
          createdAt: DateTime.now().subtract(Duration(days: 300)),
          lastActive: DateTime.now(),
          reputationScore: 95.2,
          verifiedTransactions: 890,
        ),
        SupplyChainNode(
          id: 'retailer_001',
          name: 'ScanGo Retail',
          type: NodeType.retailer,
          organization: 'ScanGo Stores',
          location: 'Kandy, Sri Lanka',
          blockchainAddress: '0x3456789012cdefg3456789012cdefg34567890',
          status: NodeStatus.active,
          metadata: {'store_count': 15},
          createdAt: DateTime.now().subtract(Duration(days: 200)),
          lastActive: DateTime.now(),
          reputationScore: 92.8,
          verifiedTransactions: 567,
        ),
      ]);
    } catch (e) {
      LoggingService.error('Failed to load nodes: $e');
    }
  }

  static Future<void> _loadProductBatches() async {
    try {
      // Mock loading product batches
      _productBatches.addAll([
        ProductBatch(
          id: 'batch_001',
          productId: 'product_001',
          productName: 'Organic Rice',
          manufacturerId: 'manufacturer_001',
          quantity: 1000,
          productionDate: DateTime.now().subtract(Duration(days: 30)),
          expiryDate: DateTime.now().add(Duration(days: 330)),
          currentLocation: 'distributor_001',
          status: BatchStatus.in_transit,
          blockchainTokenId: 'token_1234567890',
          qualityChecks: [],
          transactions: ['tx_1234567890'],
          metadata: {'grade': 'premium', 'certified': true},
          createdAt: DateTime.now().subtract(Duration(days: 30)),
          lastUpdated: DateTime.now().subtract(Duration(days: 15)),
        ),
      ]);
    } catch (e) {
      LoggingService.error('Failed to load product batches: $e');
    }
  }

  static Future<void> _loadTransactions() async {
    try {
      // Mock loading transactions
      _transactions.addAll([
        SupplyChainTransaction(
          id: 'tx_1234567890',
          batchId: 'batch_001',
          type: TransactionType.creation,
          fromNodeId: 'manufacturer_001',
          toNodeId: 'manufacturer_001',
          quantity: 1000,
          timestamp: DateTime.now().subtract(Duration(days: 30)),
          blockchainHash: 'abc123def456',
          verified: true,
          verifications: [],
          metadata: {'action': 'batch_creation'},
        ),
        SupplyChainTransaction(
          id: 'tx_1234567891',
          batchId: 'batch_001',
          type: TransactionType.transfer,
          fromNodeId: 'manufacturer_001',
          toNodeId: 'distributor_001',
          quantity: 1000,
          timestamp: DateTime.now().subtract(Duration(days: 15)),
          blockchainHash: 'def456ghi789',
          verified: true,
          verifications: [],
          metadata: {'reason': 'distribution'},
        ),
      ]);
    } catch (e) {
      LoggingService.error('Failed to load transactions: $e');
    }
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static bool get isConnected => _isConnected;
  static Blockchain? get currentBlockchain => _currentBlockchain;
  static List<SupplyChainNode> get nodes => List.from(_nodes);
  static List<ProductBatch> get productBatches => List.from(_productBatches);
  static List<SupplyChainTransaction> get transactions => List.from(_transactions);
  static Stream<BlockchainEvent> get events => _eventController?.stream ?? Stream.empty();
}

// Data models
class Blockchain {
  final String id;
  final String name;
  final String network;
  final int blockHeight;
  final String consensusAlgorithm;
  final List<SupplyChainNode> nodes;
  final DateTime createdAt;
  final DateTime lastBlockTime;

  Blockchain({
    required this.id,
    required this.name,
    required this.network,
    required this.blockHeight,
    required this.consensusAlgorithm,
    required this.nodes,
    required this.createdAt,
    required this.lastBlockTime,
  });
}

class SupplyChainNode {
  final String id;
  final String name;
  final NodeType type;
  final String organization;
  final String location;
  final String blockchainAddress;
  NodeStatus status;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  DateTime lastActive;
  double reputationScore;
  int verifiedTransactions;

  SupplyChainNode({
    required this.id,
    required this.name,
    required this.type,
    required this.organization,
    required this.location,
    required this.blockchainAddress,
    required this.status,
    required this.metadata,
    required this.createdAt,
    required this.lastActive,
    required this.reputationScore,
    required this.verifiedTransactions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'organization': organization,
      'location': location,
      'blockchain_address': blockchainAddress,
      'status': status.name,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'last_active': lastActive.toIso8601String(),
      'reputation_score': reputationScore,
      'verified_transactions': verifiedTransactions,
    };
  }
}

class ProductBatch {
  final String id;
  final String productId;
  final String productName;
  final String manufacturerId;
  int quantity;
  final DateTime productionDate;
  final DateTime expiryDate;
  String currentLocation;
  BatchStatus status;
  final String blockchainTokenId;
  final List<QualityCheck> qualityChecks;
  final List<String> transactions;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  DateTime lastUpdated;

  ProductBatch({
    required this.id,
    required this.productId,
    required this.productName,
    required this.manufacturerId,
    required this.quantity,
    required this.productionDate,
    required this.expiryDate,
    required this.currentLocation,
    required this.status,
    required this.blockchainTokenId,
    required this.qualityChecks,
    required this.transactions,
    required this.metadata,
    required this.createdAt,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'manufacturer_id': manufacturerId,
      'quantity': quantity,
      'production_date': productionDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'current_location': currentLocation,
      'status': status.name,
      'blockchain_token_id': blockchainTokenId,
      'quality_checks': qualityChecks.map((qc) => qc.toJson()).toList(),
      'transactions': transactions,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

class SupplyChainTransaction {
  final String id;
  final String batchId;
  final TransactionType type;
  final String fromNodeId;
  final String toNodeId;
  final int quantity;
  final String? reason;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final String blockchainHash;
  bool verified;
  DateTime? verifiedAt;
  final List<String> verifications;

  SupplyChainTransaction({
    required this.id,
    required this.batchId,
    required this.type,
    required this.fromNodeId,
    required this.toNodeId,
    required this.quantity,
    this.reason,
    required this.metadata,
    required this.timestamp,
    required this.blockchainHash,
    required this.verified,
    this.verifiedAt,
    required this.verifications,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'type': type.name,
      'from_node_id': fromNodeId,
      'to_node_id': toNodeId,
      'quantity': quantity,
      'reason': reason,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'blockchain_hash': blockchainHash,
      'verified': verified,
      'verified_at': verifiedAt?.toIso8601String(),
      'verifications': verifications,
    };
  }
}

class QualityCheck {
  final String id;
  final String batchId;
  final String nodeId;
  final QualityCheckType checkType;
  final bool passed;
  final String inspectorId;
  final String? notes;
  final Map<String, dynamic> checkData;
  final DateTime timestamp;
  final String blockchainHash;
  bool verified;
  DateTime? verifiedAt;

  QualityCheck({
    required this.id,
    required this.batchId,
    required this.nodeId,
    required this.checkType,
    required this.passed,
    required this.inspectorId,
    this.notes,
    required this.checkData,
    required this.timestamp,
    required this.blockchainHash,
    required this.verified,
    this.verifiedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'batch_id': batchId,
      'node_id': nodeId,
      'check_type': checkType.name,
      'passed': passed,
      'inspector_id': inspectorId,
      'notes': notes,
      'check_data': checkData,
      'timestamp': timestamp.toIso8601String(),
      'blockchain_hash': blockchainHash,
      'verified': verified,
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }
}

class SmartContract {
  final String id;
  final String name;
  final String code;
  final String deployerNodeId;
  final Map<String, dynamic> constructorArgs;
  final String blockchainAddress;
  final ContractStatus status;
  final DateTime deployedAt;
  final List<ContractFunction> functions;
  final List<ContractEvent> events;

  SmartContract({
    required this.id,
    required this.name,
    required this.code,
    required this.deployerNodeId,
    required this.constructorArgs,
    required this.blockchainAddress,
    required this.status,
    required this.deployedAt,
    required this.functions,
    required this.events,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'deployer_node_id': deployerNodeId,
      'constructor_args': constructorArgs,
      'blockchain_address': blockchainAddress,
      'status': status.name,
      'deployed_at': deployedAt.toIso8601String(),
      'functions': functions.map((f) => f.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
    };
  }
}

class SupplyChainStep {
  final String transactionId;
  final String nodeId;
  final DateTime timestamp;
  final TransactionType transactionType;
  final Map<String, dynamic> metadata;

  SupplyChainStep({
    required this.transactionId,
    required this.nodeId,
    required this.timestamp,
    required this.transactionType,
    required this.metadata,
  });
}

class SupplyChainAnalytics {
  final int totalTransactions;
  final int totalBatches;
  final Map<TransactionType, int> transactionTypeStats;
  final Map<String, int> nodeActivityStats;
  final Map<QualityCheckType, Map<String, int>> qualityCheckStats;
  final DateTime startDate;
  final DateTime endDate;

  SupplyChainAnalytics({
    required this.totalTransactions,
    required this.totalBatches,
    required this.transactionTypeStats,
    required this.nodeActivityStats,
    required this.qualityCheckStats,
    required this.startDate,
    required this.endDate,
  });
}

class BlockchainEvent {
  final BlockchainEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  BlockchainEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class SupplyChainNodeResult {
  final bool success;
  final SupplyChainNode? node;
  final String? error;

  SupplyChainNodeResult({
    required this.success,
    this.node,
    this.error,
  });
}

class ProductBatchResult {
  final bool success;
  final ProductBatch? batch;
  final String? error;

  ProductBatchResult({
    required this.success,
    this.batch,
    this.error,
  });
}

class TransactionResult {
  final bool success;
  final SupplyChainTransaction? transaction;
  final String? error;

  TransactionResult({
    required this.success,
    this.transaction,
    this.error,
  });
}

class QualityCheckResult {
  final bool success;
  final QualityCheck? qualityCheck;
  final String? error;

  QualityCheckResult({
    required this.success,
    this.qualityCheck,
    this.error,
  });
}

class SmartContractResult {
  final bool success;
  final SmartContract? contract;
  final String? error;

  SmartContractResult({
    required this.success,
    this.contract,
    this.error,
  });
}

class ProductTrackingResult {
  final bool success;
  final ProductBatch? batch;
  final List<SupplyChainTransaction>? transactions;
  final List<QualityCheck>? qualityChecks;
  final List<SupplyChainStep>? supplyChainPath;
  final bool? isAuthentic;
  final String? error;

  ProductTrackingResult({
    required this.success,
    this.batch,
    this.transactions,
    this.qualityChecks,
    this.supplyChainPath,
    this.isAuthentic,
    this.error,
  });
}

class ContractFunction {
  final String name;
  final String signature;
  final List<String> parameters;
  final String returnType;

  ContractFunction({
    required this.name,
    required this.signature,
    required this.parameters,
    required this.returnType,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'signature': signature,
      'parameters': parameters,
      'return_type': returnType,
    };
  }
}

class ContractEvent {
  final String name;
  final List<String> parameters;

  ContractEvent({
    required this.name,
    required this.parameters,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parameters': parameters,
    };
  }
}

enum NodeType {
  manufacturer,
  distributor,
  retailer,
  logistics,
  warehouse,
  quality_inspector,
}

enum NodeStatus {
  active,
  inactive,
  suspended,
  verified,
}

enum BatchStatus {
  created,
  in_transit,
  at_destination,
  sold,
  expired,
  recalled,
}

enum TransactionType {
  creation,
  transfer,
  quality_check,
  certification,
  recall,
  sale,
}

enum QualityCheckType {
  visual_inspection,
  lab_testing,
  certification,
  compliance_check,
  safety_check,
}

enum ContractStatus {
  deployed,
  active,
  paused,
  deprecated,
}

enum BlockchainEventType {
  nodeAdded,
  nodeStatusUpdated,
  batchCreated,
  productTransferred,
  qualityCheckAdded,
  qualityCheckVerified,
  transactionConfirmed,
  smartContractDeployed,
  smartContractExecuted,
  serviceDisconnected,
  error,
}
