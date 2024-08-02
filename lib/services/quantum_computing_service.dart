import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:selfcheckoutapp/services/logging_service.dart';
import 'package:selfcheckoutapp/services/cache_service.dart';
import 'package:selfcheckoutapp/services/security_service.dart';

class QuantumComputingService {
  static const String _baseUrl = 'https://api.quantum.scango.app';
  static const String _apiKey = 'quantum_computing_api_key_12345';
  static const String _cacheKey = 'quantum_computing_cache';
  
  static bool _isInitialized = false;
  static bool _isQuantumSimulatorConnected = false;
  static final Map<String, QuantumCircuit> _availableCircuits = {};
  static final Map<String, QuantumAlgorithm> _algorithms = {};
  static final List<QuantumJob> _activeJobs = [];
  static final Map<String, QuantumQubit> _qubits = {};
  static StreamController<QuantumEvent>? _eventController;

  // Quantum computing service initialization
  static Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;
      
      LoggingService.info('Initializing quantum computing service');
      
      // Initialize event controller
      _eventController = StreamController<QuantumEvent>.broadcast();
      
      // Connect to quantum simulator
      await _connectToQuantumSimulator();
      
      // Load quantum circuits
      await _loadQuantumCircuits();
      
      // Load quantum algorithms
      await _loadQuantumAlgorithms();
      
      // Initialize qubits
      await _initializeQubits();
      
      _isInitialized = true;
      
      LoggingService.info('Quantum computing service initialized successfully');
      return true;
    } catch (e) {
      LoggingService.error('Failed to initialize quantum computing service: $e');
      return false;
    }
  }

  // Quantum simulator connection
  static Future<void> _connectToQuantumSimulator() async {
    try {
      // Mock quantum simulator connection
      await Future.delayed(Duration(seconds: 3));
      
      _isQuantumSimulatorConnected = true;
      
      LoggingService.info('Connected to quantum simulator');
    } catch (e) {
      LoggingService.error('Failed to connect to quantum simulator: $e');
      _isQuantumSimulatorConnected = false;
    }
  }

  // Quantum circuit management
  static Future<CircuitResult> createQuantumCircuit({
    required String circuitId,
    required String name,
    required int numQubits,
    QuantumCircuitType type = QuantumCircuitType.general,
    Map<String, dynamic>? circuitConfig,
  }) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      if (!_isQuantumSimulatorConnected) {
        return CircuitResult(
          success: false,
          error: 'Quantum simulator not connected',
        );
      }
      
      // Create quantum circuit
      final circuit = QuantumCircuit(
        id: circuitId,
        name: name,
        type: type,
        numQubits: numQubits,
        gates: [],
        measurements: [],
        depth: 0,
        fidelity: 0.0,
        createdAt: DateTime.now(),
        lastExecuted: null,
        executionCount: 0,
        averageExecutionTime: Duration.zero,
        config: circuitConfig ?? {},
      );
      
      // Initialize qubits for circuit
      await _initializeCircuitQubits(circuit);
      
      _availableCircuits[circuitId] = circuit;
      
      // Emit circuit created event
      _emitEvent(QuantumEvent(
        type: QuantumEventType.circuitCreated,
        data: circuit.toJson(),
      ));
      
      LoggingService.info('Quantum circuit created: $circuitId');
      return CircuitResult(
        success: true,
        circuit: circuit,
      );
    } catch (e) {
      LoggingService.error('Failed to create quantum circuit: $e');
      return CircuitResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _initializeCircuitQubits(QuantumCircuit circuit) async {
    try {
      // Mock qubit initialization
      await Future.delayed(Duration(milliseconds: 500));
      
      for (int i = 0; i < circuit.numQubits; i++) {
        final qubit = QuantumQubit(
          id: '${circuit.id}_qubit_$i',
          index: i,
          state: QuantumState.zero,
          amplitude: Complex(1.0, 0.0),
          phase: 0.0,
          entangled: false,
          entangledWith: <String>[],
          measurementHistory: [],
          createdAt: DateTime.now(),
          lastModified: DateTime.now(),
        );
        
        _qubits[qubit.id] = qubit;
      }
      
      LoggingService.info('Initialized ${circuit.numQubits} qubits for circuit: ${circuit.id}');
    } catch (e) {
      LoggingService.error('Failed to initialize circuit qubits: $e');
    }
  }

  // Quantum gates
  static Future<GateResult> addGate({
    required String circuitId,
    required QuantumGateType gateType,
    required List<int> targetQubits,
    List<int>? controlQubits,
    Map<String, dynamic>? gateParameters,
  }) async {
    try {
      final circuit = _availableCircuits[circuitId];
      if (circuit == null) {
        return GateResult(
          success: false,
          error: 'Quantum circuit not found: $circuitId',
        );
      }
      
      // Validate qubit indices
      for (final index in targetQubits) {
        if (index < 0 || index >= circuit.numQubits) {
          return GateResult(
            success: false,
            error: 'Invalid qubit index: $index',
          );
        }
      }
      
      if (controlQubits != null) {
        for (final index in controlQubits) {
          if (index < 0 || index >= circuit.numQubits) {
            return GateResult(
              success: false,
              error: 'Invalid control qubit index: $index',
            );
          }
        }
      }
      
      // Create quantum gate
      final gate = QuantumGate(
        id: _generateGateId(),
        type: gateType,
        targetQubits: targetQubits,
        controlQubits: controlQubits ?? [],
        parameters: gateParameters ?? {},
        matrix: _generateGateMatrix(gateType, targetQubits.length),
        appliedAt: DateTime.now(),
      );
      
      // Apply gate to qubits
      await _applyGateToQubits(gate, circuit);
      
      circuit.gates.add(gate);
      circuit.depth++;
      
      // Update circuit fidelity
      await _updateCircuitFidelity(circuit);
      
      // Emit gate added event
      _emitEvent(QuantumEvent(
        type: QuantumEventType.gateApplied,
        data: {
          'circuit_id': circuitId,
          'gate_id': gate.id,
          'gate_type': gateType.name,
          'target_qubits': targetQubits,
        },
      ));
      
      LoggingService.info('Quantum gate applied: ${gateType.name} to circuit: $circuitId');
      return GateResult(
        success: true,
        gate: gate,
      );
    } catch (e) {
      LoggingService.error('Failed to add quantum gate: $e');
      return GateResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<void> _applyGateToQubits(QuantumGate gate, QuantumCircuit circuit) async {
    try {
      // Mock gate application
      await Future.delayed(Duration(milliseconds: 100));
      
      for (final index in gate.targetQubits) {
        final qubitId = '${circuit.id}_qubit_$index';
        final qubit = _qubits[qubitId];
        
        if (qubit != null) {
          // Apply gate transformation
          await _transformQubitState(qubit, gate);
          qubit.lastModified = DateTime.now();
        }
      }
      
      // Handle entanglement for controlled gates
      if (gate.controlQubits.isNotEmpty) {
        await _createEntanglement(gate, circuit);
      }
      
      LoggingService.info('Applied gate to qubits: ${gate.type.name}');
    } catch (e) {
      LoggingService.error('Failed to apply gate to qubits: $e');
    }
  }

  static Future<void> _transformQubitState(QuantumQubit qubit, QuantumGate gate) async {
    try {
      switch (gate.type) {
        case QuantumGateType.hadamard:
          // Apply Hadamard gate: H|0⟩ = (|0⟩ + |1⟩)/√2
          qubit.state = QuantumState.superposition;
          qubit.amplitude = Complex(1.0 / sqrt(2), 0.0);
          qubit.phase = 0.0;
          break;
        case QuantumGateType.pauliX:
          // Apply Pauli-X gate: X|0⟩ = |1⟩, X|1⟩ = |0⟩
          if (qubit.state == QuantumState.zero) {
            qubit.state = QuantumState.one;
          } else if (qubit.state == QuantumState.one) {
            qubit.state = QuantumState.zero;
          }
          qubit.phase += pi;
          break;
        case QuantumGateType.pauliY:
          // Apply Pauli-Y gate: Y|0⟩ = i|1⟩, Y|1⟩ = -i|0⟩
          if (qubit.state == QuantumState.zero) {
            qubit.state = QuantumState.one;
            qubit.phase = pi / 2;
          } else if (qubit.state == QuantumState.one) {
            qubit.state = QuantumState.zero;
            qubit.phase = -pi / 2;
          }
          break;
        case QuantumGateType.pauliZ:
          // Apply Pauli-Z gate: Z|0⟩ = |0⟩, Z|1⟩ = -|1⟩
          if (qubit.state == QuantumState.one) {
            qubit.phase += pi;
          }
          break;
        case QuantumGateType.phase:
          // Apply phase gate with parameter
          final phase = gate.parameters['phase'] as double? ?? 0.0;
          qubit.phase += phase;
          break;
        case QuantumGateType.cnot:
          // CNOT gate is handled in entanglement
          break;
        case QuantumGateType.swap:
          // SWAP gate exchanges states of two qubits
          // This is handled in entanglement
          break;
      }
    } catch (e) {
      LoggingService.error('Failed to transform qubit state: $e');
    }
  }

  static Future<void> _createEntanglement(QuantumGate gate, QuantumCircuit circuit) async {
    try {
      // Mock entanglement creation
      await Future.delayed(Duration(milliseconds: 200));
      
      switch (gate.type) {
        case QuantumGateType.cnot:
          if (gate.targetQubits.length == 1 && gate.controlQubits.length == 1) {
            final controlIndex = gate.controlQubits.first;
            final targetIndex = gate.targetQubits.first;
            
            final controlQubitId = '${circuit.id}_qubit_$controlIndex';
            final targetQubitId = '${circuit.id}_qubit_$targetIndex';
            
            final controlQubit = _qubits[controlQubitId];
            final targetQubit = _qubits[targetQubitId];
            
            if (controlQubit != null && targetQubit != null) {
              // Create entanglement
              controlQubit.entangled = true;
              controlQubit.entangledWith.add(targetQubitId);
              
              targetQubit.entangled = true;
              targetQubit.entangledWith.add(controlQubitId);
              
              // Apply CNOT transformation
              if (controlQubit.state == QuantumState.one) {
                if (targetQubit.state == QuantumState.zero) {
                  targetQubit.state = QuantumState.one;
                } else if (targetQubit.state == QuantumState.one) {
                  targetQubit.state = QuantumState.zero;
                }
              }
            }
          }
          break;
        case QuantumGateType.swap:
          if (gate.targetQubits.length == 2) {
            final index1 = gate.targetQubits[0];
            final index2 = gate.targetQubits[1];
            
            final qubit1Id = '${circuit.id}_qubit_$index1';
            final qubit2Id = '${circuit.id}_qubit_$index2';
            
            final qubit1 = _qubits[qubit1Id];
            final qubit2 = _qubits[qubit2Id];
            
            if (qubit1 != null && qubit2 != null) {
              // Swap states
              final tempState = qubit1.state;
              final tempAmplitude = qubit1.amplitude;
              final tempPhase = qubit1.phase;
              
              qubit1.state = qubit2.state;
              qubit1.amplitude = qubit2.amplitude;
              qubit1.phase = qubit2.phase;
              
              qubit2.state = tempState;
              qubit2.amplitude = tempAmplitude;
              qubit2.phase = tempPhase;
              
              // Create entanglement
              qubit1.entangled = true;
              qubit1.entangledWith.add(qubit2Id);
              
              qubit2.entangled = true;
              qubit2.entangledWith.add(qubit1Id);
            }
          }
          break;
      }
      
      LoggingService.info('Created entanglement for gate: ${gate.type.name}');
    } catch (e) {
      LoggingService.error('Failed to create entanglement: $e');
    }
  }

  static List<List<Complex>> _generateGateMatrix(QuantumGateType gateType, int size) {
    // Mock gate matrix generation
    switch (gateType) {
      case QuantumGateType.hadamard:
        return [
          [Complex(1.0 / sqrt(2), 0.0), Complex(1.0 / sqrt(2), 0.0)],
          [Complex(1.0 / sqrt(2), 0.0), Complex(-1.0 / sqrt(2), 0.0)],
        ];
      case QuantumGateType.pauliX:
        return [
          [Complex(0.0, 0.0), Complex(1.0, 0.0)],
          [Complex(1.0, 0.0), Complex(0.0, 0.0)],
        ];
      case QuantumGateType.pauliY:
        return [
          [Complex(0.0, 0.0), Complex(0.0, -1.0)],
          [Complex(0.0, 1.0), Complex(0.0, 0.0)],
        ];
      case QuantumGateType.pauliZ:
        return [
          [Complex(1.0, 0.0), Complex(0.0, 0.0)],
          [Complex(0.0, 0.0), Complex(-1.0, 0.0)],
        ];
      case QuantumGateType.cnot:
        return [
          [Complex(1.0, 0.0), Complex(0.0, 0.0), Complex(0.0, 0.0), Complex(0.0, 0.0)],
          [Complex(0.0, 0.0), Complex(1.0, 0.0), Complex(0.0, 0.0), Complex(0.0, 0.0)],
          [Complex(0.0, 0.0), Complex(0.0, 0.0), Complex(0.0, 0.0), Complex(1.0, 0.0)],
          [Complex(0.0, 0.0), Complex(0.0, 0.0), Complex(0.0, 0.0), Complex(0.0, 0.0)],
        ];
      case QuantumGateType.swap:
        return [
          [Complex(1.0, 0.0), Complex(0.0, 0.0), Complex(0.0, 0.0), Complex(0.0, 0.0)],
          [Complex(0.0, 0.0), Complex(0.0, 0.0), Complex(1.0, 0.0), Complex(0.0, 0.0)],
          [Complex(0.0, 0.0), Complex(1.0, 0.0), Complex(0.0, 0.0), Complex(0.0, 0.0)],
          [Complex(0.0, 0.0), Complex(0.0, 0.0), Complex(0.0, 0.0), Complex(1.0, 0.0)],
        ];
      default:
        return [
          [Complex(1.0, 0.0), Complex(0.0, 0.0)],
          [Complex(0.0, 0.0), Complex(1.0, 0.0)],
        ];
    }
  }

  static Future<void> _updateCircuitFidelity(QuantumCircuit circuit) async {
    try {
      // Mock fidelity calculation
      await Future.delayed(Duration(milliseconds: 100));
      
      // Calculate fidelity based on circuit depth and gate types
      double baseFidelity = 1.0;
      
      // Reduce fidelity with circuit depth
      baseFidelity -= (circuit.depth * 0.01);
      
      // Reduce fidelity for multi-qubit gates
      for (final gate in circuit.gates) {
        if (gate.controlQubits.isNotEmpty) {
          baseFidelity -= 0.02;
        }
      }
      
      // Add random noise
      baseFidelity += (Random().nextDouble() - 0.5) * 0.1;
      
      circuit.fidelity = baseFidelity.clamp(0.0, 1.0);
    } catch (e) {
      LoggingService.error('Failed to update circuit fidelity: $e');
    }
  }

  // Quantum measurements
  static Future<MeasurementResult> measureQubits({
    required String circuitId,
    required List<int> qubitIndices,
    MeasurementBasis basis = MeasurementBasis.computational,
    int shots = 1024,
  }) async {
    try {
      final circuit = _availableCircuits[circuitId];
      if (circuit == null) {
        return MeasurementResult(
          success: false,
          error: 'Quantum circuit not found: $circuitId',
        );
      }
      
      // Validate qubit indices
      for (final index in qubitIndices) {
        if (index < 0 || index >= circuit.numQubits) {
          return MeasurementResult(
            success: false,
            error: 'Invalid qubit index: $index',
          );
        }
      }
      
      // Perform measurements
      final measurements = <MeasurementResult>[];
      
      for (final index in qubitIndices) {
        final qubitId = '${circuit.id}_qubit_$index';
        final qubit = _qubits[qubitId];
        
        if (qubit != null) {
          final result = await _performMeasurement(qubit, basis, shots);
          measurements.add(result);
          
          // Add to measurement history
          qubit.measurementHistory.add(result);
          
          // Update qubit state based on measurement
          qubit.state = result.measuredState;
          qubit.amplitude = Complex(1.0, 0.0);
          qubit.phase = 0.0;
          qubit.lastModified = DateTime.now();
        }
      }
      
      // Create measurement result
      final measurementResult = MeasurementResult(
        success: true,
        circuitId: circuitId,
        qubitIndices: qubitIndices,
        basis: basis,
        shots: shots,
        results: measurements,
        timestamp: DateTime.now(),
      );
      
      // Add measurement to circuit
      circuit.measurements.add(measurementResult);
      
      // Emit measurement event
      _emitEvent(QuantumEvent(
        type: QuantumEventType.measurementPerformed,
        data: measurementResult.toJson(),
      ));
      
      LoggingService.info('Quantum measurement performed: $circuitId');
      return measurementResult;
    } catch (e) {
      LoggingService.error('Failed to measure qubits: $e');
      return MeasurementResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<MeasurementResult> _performMeasurement(
    QuantumQubit qubit,
    MeasurementBasis basis,
    int shots,
  ) async {
    try {
      // Mock measurement
      await Future.delayed(Duration(milliseconds: 300));
      
      // Calculate measurement probabilities
      double probabilityZero = 0.5;
      double probabilityOne = 0.5;
      
      switch (qubit.state) {
        case QuantumState.zero:
          probabilityZero = 0.9;
          probabilityOne = 0.1;
          break;
        case QuantumState.one:
          probabilityZero = 0.1;
          probabilityOne = 0.9;
          break;
        case QuantumState.superposition:
          probabilityZero = 0.5;
          probabilityOne = 0.5;
          break;
      }
      
      // Add noise
      probabilityZero += (Random().nextDouble() - 0.5) * 0.1;
      probabilityOne += (Random().nextDouble() - 0.5) * 0.1;
      
      // Normalize probabilities
      final total = probabilityZero + probabilityOne;
      probabilityZero /= total;
      probabilityOne /= total;
      
      // Perform shots
      int zeroCount = 0;
      int oneCount = 0;
      
      for (int i = 0; i < shots; i++) {
        if (Random().nextDouble() < probabilityZero) {
          zeroCount++;
        } else {
          oneCount++;
        }
      }
      
      // Determine measured state
      final measuredState = zeroCount > oneCount ? QuantumState.zero : QuantumState.one;
      
      return MeasurementResult(
        success: true,
        circuitId: '',
        qubitIndices: [],
        basis: basis,
        shots: shots,
        results: [],
        timestamp: DateTime.now(),
        measuredState: measuredState,
        probabilityZero: zeroCount / shots,
        probabilityOne: oneCount / shots,
        zeroCount: zeroCount,
        oneCount: oneCount,
      );
    } catch (e) {
      LoggingService.error('Failed to perform measurement: $e');
      return MeasurementResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Quantum algorithms
  static Future<AlgorithmResult> runQuantumAlgorithm({
    required String algorithmId,
    required String circuitId,
    Map<String, dynamic>? algorithmParameters,
  }) async {
    try {
      final circuit = _availableCircuits[circuitId];
      if (circuit == null) {
        return AlgorithmResult(
          success: false,
          error: 'Quantum circuit not found: $circuitId',
        );
      }
      
      final algorithm = _algorithms[algorithmId];
      if (algorithm == null) {
        return AlgorithmResult(
          success: false,
          error: 'Quantum algorithm not found: $algorithmId',
        );
      }
      
      // Create quantum job
      final job = QuantumJob(
        id: _generateJobId(),
        algorithmId: algorithmId,
        circuitId: circuitId,
        status: QuantumJobStatus.running,
        createdAt: DateTime.now(),
        startedAt: DateTime.now(),
        completedAt: null,
        executionTime: Duration.zero,
        result: null,
        error: null,
        parameters: algorithmParameters ?? {},
        metadata: {},
      );
      
      _activeJobs.add(job);
      
      // Execute algorithm
      final executionResult = await _executeQuantumAlgorithm(job, algorithm, circuit);
      
      // Update job
      final jobIndex = _activeJobs.indexWhere((j) => j.id == job.id);
      if (jobIndex != -1) {
        _activeJobs[jobIndex] = executionResult;
      }
      
      // Update circuit statistics
      circuit.executionCount++;
      circuit.lastExecuted = DateTime.now();
      
      // Update algorithm statistics
      await _updateAlgorithmStatistics(algorithm, executionResult);
      
      // Emit algorithm completed event
      _emitEvent(QuantumEvent(
        type: executionResult.success ? QuantumEventType.algorithmCompleted : QuantumEventType.algorithmFailed,
        data: executionResult.toJson(),
      ));
      
      LoggingService.info('Quantum algorithm executed: $algorithmId -> ${executionResult.success ? 'SUCCESS' : 'FAILURE'}');
      return AlgorithmResult(
        success: executionResult.success,
        job: executionResult,
      );
    } catch (e) {
      LoggingService.error('Failed to run quantum algorithm: $e');
      return AlgorithmResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  static Future<QuantumJob> _executeQuantumAlgorithm(
    QuantumJob job,
    QuantumAlgorithm algorithm,
    QuantumCircuit circuit,
  ) async {
    try {
      job.status = QuantumJobStatus.running;
      
      final startTime = DateTime.now();
      
      // Mock algorithm execution
      await Future.delayed(Duration(seconds: 2 + Random().nextInt(3)));
      
      switch (algorithm.type) {
        case QuantumAlgorithmType.grover:
          return await _executeGroverAlgorithm(job, algorithm, circuit);
        case QuantumAlgorithmType.shor:
          return await _executeShorAlgorithm(job, algorithm, circuit);
        case QuantumAlgorithmType.qft:
          return await _executeQFTAlgorithm(job, algorithm, circuit);
        case QuantumAlgorithmType.vqe:
          return await _executeVQEAlgorithm(job, algorithm, circuit);
        case QuantumAlgorithmType.bernsteinVazirani:
          return await _executeBernsteinVaziraniAlgorithm(job, algorithm, circuit);
        case QuantumAlgorithmType.deutschJozsa:
          return await _executeDeutschJozsaAlgorithm(job, algorithm, circuit);
        default:
          return await _executeGenericAlgorithm(job, algorithm, circuit);
      }
    } catch (e) {
      LoggingService.error('Failed to execute quantum algorithm: $e');
      
      job.status = QuantumJobStatus.failed;
      job.error = e.toString();
      job.completedAt = DateTime.now();
      job.executionTime = job.completedAt!.difference(job.startedAt!);
      
      return job;
    }
  }

  static Future<QuantumJob> _executeGroverAlgorithm(
    QuantumJob job,
    QuantumAlgorithm algorithm,
    QuantumCircuit circuit,
  ) async {
    try {
      // Mock Grover's algorithm execution
      final iterations = job.parameters['iterations'] as int? ?? 10;
      
      // Add oracle and diffusion operators
      for (int i = 0; i <iterations; i++) {
        // Oracle
        await _addGate(
          circuitId: circuit.id,
          gateType: QuantumGateType.phase,
          targetQubits: [0],
          gateParameters: {'phase': pi},
        );
        
        // Diffusion
        await _addGate(
          circuitId: circuit.id,
          gateType: QuantumGateType.hadamard,
          targetQubits: [0],
        );
        
        await _addGate(
          circuitId: circuit.id,
          gateType: QuantumGateType.pauliX,
          targetQubits: [0],
        );
        
        await _addGate(
          circuitId: circuit.id,
          gateType: QuantumGateType.hadamard,
          targetQubits: [0],
        );
      }
      
      // Final measurement
      final measurement = await measureQubits(
        circuitId: circuit.id,
        qubitIndices: [0],
      );
      
      job.status = QuantumJobStatus.completed;
      job.completedAt = DateTime.now();
      job.executionTime = job.completedAt!.difference(job.startedAt!);
      job.result = {
        'algorithm': 'Grover',
        'iterations': iterations,
        'measurement': measurement.toJson(),
        'success': measurement.results.isNotEmpty && measurement.results.first.success,
      };
      
      return job;
    } catch (e) {
      LoggingService.error('Failed to execute Grover algorithm: $e');
      rethrow;
    }
  }

  static Future<QuantumJob> _executeShorAlgorithm(
    QuantumJob job,
    QuantumAlgorithm algorithm,
    QuantumCircuit circuit,
  ) async {
    try {
      // Mock Shor's algorithm execution
      final n = job.parameters['n'] as int? ?? 15;
      
      // Add quantum gates for Shor's algorithm
      await _addGate(
        circuitId: circuit.id,
        gateType: QuantumGateType.hadamard,
        targetQubits: List.generate(n, (i) => i),
      );
      
      // Add controlled operations
      for (int i = 0; i < n; i++) {
        await _addGate(
          circuitId: circuit.id,
          gateType: QuantumGateType.cnot,
          targetQubits: [i, (i + 1) % n],
          controlQubits: [n],
        );
      }
      
      // Final measurement
      final measurement = await measureQubits(
        circuitId: circuit.id,
        qubitIndices: List.generate(n, (i) => i),
      );
      
      job.status = QuantumJobStatus.completed;
      job.completedAt = DateTime.now();
      job.executionTime = job.completedAt!.difference(job.startedAt!);
      job.result = {
        'algorithm': 'Shor',
        'n': n,
        'measurement': measurement.toJson(),
        'success': measurement.results.isNotEmpty && measurement.results.first.success,
      };
      
      return job;
    } catch (e) {
      LoggingService.error('Failed to execute Shor algorithm: $e');
      rethrow;
    }
  }

  static Future<QuantumJob> _executeQFTAlgorithm(
    QuantumJob job,
    QuantumAlgorithm algorithm,
    QuantumCircuit circuit,
  ) async {
    try {
      final n = circuit.numQubits;
      
      // Add Hadamard gates
      for (int i = 0; i < n; i++) {
        await _addGate(
          circuitId: circuit.id,
          gateType: QuantumGateType.hadamard,
          targetQubits: [i],
        );
      }
      
      // Add controlled phase rotations
      for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++) {
          await _addGate(
            circuitId: circuit.id,
            gateType: QuantumGateType.cnot,
            targetQubits: [j, i],
            controlQubits: [n],
          );
          
          await _addGate(
            circuitId: circuit.id,
            gateType: QuantumGateType.phase,
            targetQubits: [j],
            gateParameters: {'phase': 2 * pi * i * j / (1 << n)},
          );
          
          await _addGate(
            circuitId: circuit.id,
            gateType: QuantumGateType.cnot,
            targetQubits: [j, i],
            controlQubits: [n],
          );
        }
      }
      
      // Add inverse QFT
      for (int i = n - 1; i >= 0; i--) {
        await _addGate(
          circuitId: circuit.id,
          gateType: QuantumGateType.hadamard,
          targetQubits: [i],
        );
      }
      
      job.status = QuantumJobStatus.completed;
      job.completedAt = DateTime.now();
      job.executionTime = job.completedAt!.difference(job.startedAt!);
      job.result = {
        'algorithm': 'QFT',
        'n': n,
        'success': true,
      };
      
      return job;
    } catch (e) {
      LoggingService.error('Failed to execute QFT algorithm: $e');
      rethrow;
    }
  }

  static Future<QuantumJob> _executeVQEAlgorithm(
    QuantumJob job,
    QuantumAlgorithm algorithm,
    QuantumCircuit circuit,
  ) async {
    try {
      // Mock VQE execution
      final layers = job.parameters['layers'] as int? ?? 5;
      
      // Add parameterized gates
      for (int layer = 0; layer < layers; layer++) {
        // Add parameterized single-qubit rotations
        for (int i = 0; i < circuit.numQubits; i++) {
          await _addGate(
            circuitId: circuit.id,
            gateType: QuantumGateType.phase,
            targetQubits: [i],
            gateParameters: {'phase': Random().nextDouble() * 2 * pi},
          );
        }
        
        // Add entangling gates
        for (int i = 0; i < circuit.numQubits - 1; i++) {
          await _addGate(
            circuitId: circuit.id,
            gateType: QuantumGateType.cnot,
            targetQubits: [i, i + 1],
          );
        }
      }
      
      job.status = QuantumJobStatus.completed;
      job.completedAt = DateTime.now();
      job.executionTime = job.completedAt!.difference(job.startedAt!);
      job.result = {
        'algorithm': 'VQE',
        'layers': layers,
        'success': true,
      };
      
      return job;
    } catch (e) {
      LoggingService.error('Failed to execute VQE algorithm: $e');
      rethrow;
    }
  }

  static Future<QuantumJob> _executeBernsteinVaziraniAlgorithm(
    QuantumJob job,
    QuantumAlgorithm algorithm,
    QuantumCircuit circuit,
  ) async {
    try {
      // Mock Bernstein-Vazirani algorithm
      final n = circuit.numQubits;
      
      // Add oracle
      await _addGate(
        circuitId: circuit.id,
        gateType: QuantumGateType.phase,
        targetQubits: [n - 1],
        gateParameters: {'phase': pi},
      );
      
      // Add diffusion operator
      await _addGate(
        circuitId: circuit.id,
        gateType: QuantumGateType.hadamard,
        targetQubits: [n - 1],
      );
      
      await _addGate(
        circuitId: circuit.id,
        gateType: QuantumGateType.hadamard,
        targetQubits: List.generate(n - 1, (i) => i),
      );
      
      await _addGate(
        circuitId: circuit.id,
        gateType: QuantumGateType.cnot,
        targetQubits: [n - 1, 0],
        controlQubits: List.generate(n - 1, (i) => i),
      );
      
      await _addGate(
        circuitId: circuit.id,
        gateType: QuantumGateType.hadamard,
        targetQubits: List.generate(n - 1, (i) => i),
      );
      
      await _addGate(
        circuitId: circuit.id,
        gateType: QuantumGateType.hadamard,
        targetQubits: [n - 1],
      );
      
      // Measurement
      final measurement = await measureQubits(
        circuitId: circuit.id,
        qubitIndices: [n - 1],
      );
      
      job.status = QuantumJobStatus.completed;
      job.completedAt = DateTime.now();
      job.executionTime = job.completedAt!.difference(job.startedAt!);
      job.result = {
        'algorithm': 'Bernstein-Vazirani',
        'n': n,
        'measurement': measurement.toJson(),
        'success': measurement.results.isNotEmpty && measurement.results.first.success,
      };
      
      return job;
    } catch (e) {
      LoggingService.error('Failed to execute Bernstein-Vazirani algorithm: $e');
      rethrow;
    }
  }

  static Future<QuantumJob> _executeDeutschJozsaAlgorithm(
    QuantumJob job,
    QuantumAlgorithm algorithm,
    QuantumCircuit circuit,
  ) async {
    try {
      // Mock Deutsch-Jozsa algorithm
      final n = circuit.numQubits;
      
      // Add Hadamard gates
      for (int i = 0; i < n; i++) {
        await _addGate(
          circuitId: circuit.id,
          gateType: QuantumGateType.hadamard,
          targetQubits: [i],
        );
      }
      
      // Add oracle
      await _addGate(
        circuitId: circuit.id,
        gateType: QuantumGateType.pauliX,
        targetQubits: [n - 1],
        controlQubits: List.generate(n - 1, (i) => i),
      );
      
      // Add Hadamard gates
      for (int i = 0; i < n; i++) {
        await _addGate(
          circuitId: circuit.id,
          gateType: QuantumGateType.hadamard,
          targetQubits: [i],
        );
      }
      
      // Measurement
      final measurement = await measureQubits(
        circuitId: circuit.id,
        qubitIndices: [n - 1],
      );
      
      job.status = QuantumJobStatus.completed;
      job.completedAt = DateTime.now();
      job.executionTime = job.completedAt!.difference(job.startedAt!);
      job.result = {
        'algorithm': 'Deutsch-Jozsa',
        'n': n,
        'measurement': measurement.toJson(),
        'success': measurement.results.isNotEmpty && measurement.results.first.success,
      };
      
      return job;
    } catch (e) {
      LoggingService.error('Failed to execute Deutsch-Jozsa algorithm: $e');
      rethrow;
    }
  }

  static Future<QuantumJob> _executeGenericAlgorithm(
    QuantumJob job,
    QuantumAlgorithm algorithm,
    QuantumCircuit circuit,
  ) async {
    try {
      // Mock generic algorithm execution
      await Future.delayed(Duration(seconds: 1));
      
      job.status = QuantumJobStatus.completed;
      job.completedAt = DateTime.now();
      job.executionTime = job.completedAt!.difference(job.startedAt!);
      job.result = {
        'algorithm': algorithm.name,
        'success': true,
      };
      
      return job;
    } catch (e) {
      LoggingService.error('Failed to execute generic algorithm: $e');
      rethrow;
    }
  }

  static Future<void> _updateAlgorithmStatistics(QuantumAlgorithm algorithm, QuantumJob job) async {
    try {
      algorithm.executionCount++;
      
      // Update average execution time
      final totalTime = algorithm.averageExecutionTime.inMilliseconds * (algorithm.executionCount - 1) + job.executionTime.inMilliseconds;
      algorithm.averageExecutionTime = Duration(milliseconds: (totalTime / algorithm.executionCount).round());
      
      // Update success rate
      if (!job.success) {
        final errorCount = (algorithm.errorRate * (algorithm.executionCount - 1)) + 1;
        algorithm.errorRate = errorCount / algorithm.executionCount;
      } else {
        final errorCount = algorithm.errorRate * (algorithm.executionCount - 1);
        algorithm.errorRate = errorCount / algorithm.executionCount;
      }
      
      algorithm.lastExecuted = DateTime.now();
    } catch (e) {
      LoggingService.error('Failed to update algorithm statistics: $e');
    }
  }

  // Quantum analytics
  static Future<QuantumAnalytics> getAnalytics({
    String? circuitId,
    String? algorithmId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var circuits = List<QuantumCircuit>.from(_availableCircuits.values);
      var algorithms = List<QuantumAlgorithm>.from(_algorithms.values);
      var jobs = List<QuantumJob>.from(_activeJobs);
      
      if (circuitId != null) {
        circuits = circuits.where((c) => c.id == circuitId).toList();
      }
      
      if (algorithmId != null) {
        algorithms = algorithms.where((a) => a.id == algorithmId).toList();
      }
      
      if (startDate != null) {
        jobs = jobs.where((j) => j.createdAt.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        jobs = jobs.where((j) => j.createdAt.isBefore(endDate)).toList();
      }
      
      final circuitTypeStats = <QuantumCircuitType, int>{};
      final algorithmTypeStats = <QuantumAlgorithmType, int>{};
      final jobStatusStats = <QuantumJobStatus, int>{};
      
      for (final circuit in circuits) {
        circuitTypeStats[circuit.type] = (circuitTypeStats[circuit.type] ?? 0) + 1;
      }
      
      for (final algorithm in algorithms) {
        algorithmTypeStats[algorithm.type] = (algorithmTypeStats[algorithm.type] ?? 0) + 1;
      }
      
      for (final job in jobs) {
        jobStatusStats[job.status] = (jobStatusStats[job.status] ?? 0) + 1;
      }
      
      return QuantumAnalytics(
        totalCircuits: circuits.length,
        totalAlgorithms: algorithms.length,
        totalJobs: jobs.length,
        circuitTypeStats: circuitTypeStats,
        algorithmTypeStats: algorithmTypeStats,
        jobStatusStats: jobStatusStats,
        averageCircuitFidelity: _calculateAverageCircuitFidelity(circuits),
        averageAlgorithmExecutionTime: _calculateAverageAlgorithmExecutionTime(algorithms),
        averageQuantumCoherence: _calculateAverageQuantumCoherence(),
        startDate: startDate ?? DateTime.now().subtract(Duration(days: 30)),
        endDate: endDate ?? DateTime.now(),
      );
    } catch (e) {
      LoggingService.error('Failed to get quantum analytics: $e');
      return QuantumAnalytics(
        totalCircuits: 0,
        totalAlgorithms: 0,
        totalJobs: 0,
        circuitTypeStats: {},
        algorithmTypeStats: {},
        jobStatusStats: {},
        averageCircuitFidelity: 0.0,
        averageAlgorithmExecutionTime: Duration.zero,
        averageQuantumCoherence: 0.0,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      );
    }
  }

  static double _calculateAverageCircuitFidelity(List<QuantumCircuit> circuits) {
    if (circuits.isEmpty) return 0.0;
    
    double totalFidelity = 0.0;
    
    for (final circuit in circuits) {
      totalFidelity += circuit.fidelity;
    }
    
    return totalFidelity / circuits.length;
  }

  static Duration _calculateAverageAlgorithmExecutionTime(List<QuantumAlgorithm> algorithms) {
    if (algorithms.isEmpty) return Duration.zero;
    
    int totalMilliseconds = 0;
    
    for (final algorithm in algorithms) {
      totalMilliseconds += algorithm.averageExecutionTime.inMilliseconds;
    }
    
    return Duration(milliseconds: totalMilliseconds ~/ algorithms.length);
  }

  static double _calculateAverageQuantumCoherence() {
    // Mock quantum coherence calculation
    return 0.85 + Random().nextDouble() * 0.1; // 85-95%
  }

  // Event handling
  static void _emitEvent(QuantumEvent event) {
    _eventController?.add(event);
  }

  // Data loading
  static Future<void> _loadQuantumCircuits() async {
    try {
      // Mock loading quantum circuits
      _availableCircuits.addAll([
        QuantumCircuit(
          id: 'circuit_1',
          name: 'Bell State Circuit',
          type: QuantumCircuitType.entanglement,
          numQubits: 2,
          gates: [],
          measurements: [],
          depth: 0,
          fidelity: 0.95,
          createdAt: DateTime.now().subtract(Duration(days: 7)),
          lastExecuted: null,
          executionCount: 0,
          averageExecutionTime: Duration.zero,
          config: {},
        ),
        QuantumCircuit(
          id: 'circuit_2',
          name: 'GHZ State Circuit',
          type: QuantumCircuitType.ghz,
          numQubits: 3,
          gates: [],
          measurements: [],
          depth: 0,
          fidelity: 0.92,
          createdAt: DateTime.now().subtract(Duration(days: 5)),
          lastExecuted: null,
          executionCount: 0,
          averageExecutionTime: Duration.zero,
          config: {},
        ),
        QuantumCircuit(
          id: 'circuit_3',
          name: 'QFT Circuit',
          type: QuantumCircuitType.qft,
          numQubits: 4,
          gates: [],
          measurements: [],
          depth: 0,
          fidelity: 0.88,
          createdAt: DateTime.now().subtract(Duration(days: 3)),
          lastExecuted: null,
          executionCount: 0,
          averageExecutionTime: Duration.zero,
          config: {},
        ),
      ]);
    } catch (e) {
      LoggingService.error('Failed to load quantum circuits: $e');
    }
  }

  static Future<void> _loadQuantumAlgorithms() async {
    try {
      // Mock loading quantum algorithms
      _algorithms.addAll([
        QuantumAlgorithm(
          id: 'grover',
          name: 'Grover\'s Algorithm',
          type: QuantumAlgorithmType.grover,
          description: 'Quantum search algorithm for unstructured search',
          complexity: 'O(√N)',
          requiredQubits: 1,
          createdAt: DateTime.now().subtract(Duration(days: 10)),
          lastExecuted: null,
          executionCount: 0,
          averageExecutionTime: Duration(seconds: 5),
          errorRate: 0.02,
          config: {},
        ),
        QuantumAlgorithm(
          id: 'shor',
          name: 'Shor\'s Algorithm',
          type: QuantumAlgorithmType.shor,
          description: 'Quantum algorithm for integer factorization',
          complexity: 'O((log N)^3)',
          requiredQubits: 15,
          createdAt: DateTime.now().subtract(Duration(days: 8)),
          lastExecuted: null,
          executionCount: 0,
          averageExecutionTime: Duration(seconds: 10),
          errorRate: 0.01,
          config: {},
        ),
        QuantumAlgorithm(
          id: 'qft',
          name: 'Quantum Fourier Transform',
          type: QuantumAlgorithmType.qft,
          description: 'Quantum algorithm for Fourier transform',
          complexity: 'O(N log N)',
          requiredQubits: 4,
          createdAt: DateTime.now().subtract(Duration(days: 6)),
          lastExecuted: null,
          executionCount: 0,
          averageExecutionTime: Duration(seconds: 3),
          errorRate: 0.005,
          config: {},
        ),
        QuantumAlgorithm(
          id: 'vqe',
          name: 'Variational Quantum Eigensolver',
          type: QuantumAlgorithmType.vqe,
          description: 'Hybrid quantum-classical algorithm for eigenvalue problems',
          complexity: 'O(poly(N))',
          requiredQubits: 4,
          createdAt: DateTime.now().subtract(Duration(days: 4)),
          lastExecuted: null,
          executionCount: 0,
          averageExecutionTime: Duration(seconds: 8),
          errorRate: 0.03,
          config: {},
        ),
        QuantumAlgorithm(
          id: 'bernstein_vazirani',
          name: 'Bernstein-Vazirani Algorithm',
          type: QuantumAlgorithmType.bernsteinVazirani,
          description: 'Quantum algorithm for promise problem',
          complexity: 'O(1)',
          requiredQubits: 1,
          createdAt: DateTime.now().subtract(Duration(days: 2)),
          lastExecuted: null,
          executionCount: 0,
          averageExecutionTime: Duration(seconds: 2),
          errorRate: 0.01,
          config: {},
        ),
        QuantumAlgorithm(
          id: 'deutsch_jozsa',
          name: 'Deutsch-Jozsa Algorithm',
          type: QuantumAlgorithmType.deutschJozsa,
          description: 'Quantum algorithm for evaluating boolean functions',
          complexity: 'O(1)',
          requiredQubits: 1,
          createdAt: DateTime.now().subtract(Duration(days: 1)),
          lastExecuted: null,
          executionCount: 0,
          averageExecutionTime: Duration(seconds: 1),
          errorRate: 0.005,
          config: {},
        ),
      ]);
    } catch (e) {
      LoggingService.error('Failed to load quantum algorithms: $e');
    }
  }

  static Future<void> _initializeQubits() async {
    try {
      // Initialize qubits for all circuits
      for (final circuit in _availableCircuits.values) {
        await _initializeCircuitQubits(circuit);
      }
    } catch (e) {
      LoggingService.error('Failed to initialize qubits: $e');
    }
  }

  // Utility methods
  static String _generateGateId() {
    return 'gate_${DateTime.now().millisecondsSinceEpoch}';
  }

  static String _generateJobId() {
    return 'job_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Getters
  static bool get isInitialized => _isInitialized;
  static bool get isQuantumSimulatorConnected => _isQuantumSimulatorConnected;
  static Map<String, QuantumCircuit> get availableCircuits => Map.from(_availableCircuits);
  static Map<String, QuantumAlgorithm> get algorithms => Map.from(_algorithms);
  static List<QuantumJob> get activeJobs => List.from(_activeJobs);
  static Map<String, QuantumQubit> get qubits => Map.from(_qubits);
  static Stream<QuantumEvent> get events => _eventController?.stream ?? Stream.empty();
}

// Data models
class QuantumCircuit {
  final String id;
  final String name;
  final QuantumCircuitType type;
  final int numQubits;
  final List<QuantumGate> gates;
  final List<MeasurementResult> measurements;
  int depth;
  double fidelity;
  final DateTime createdAt;
  final DateTime? lastExecuted;
  int executionCount;
  Duration averageExecutionTime;
  final Map<String, dynamic> config;

  QuantumCircuit({
    required this.id,
    required this.name,
    required this.type,
    required this.numQubits,
    required this.gates,
    required this.measurements,
    required this.depth,
    required this.fidelity,
    required this.createdAt,
    this.lastExecuted,
    required this.executionCount,
    required this.averageExecutionTime,
    required this.config,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'num_qubits': numQubits,
      'gates': gates.map((g) => g.toJson()).toList(),
      'measurements': measurements.map((m) => m.toJson()).toList(),
      'depth': depth,
      'fidelity': fidelity,
      'created_at': createdAt.toIso8601String(),
      'last_executed': lastExecuted?.toIso8601String(),
      'execution_count': executionCount,
      'average_execution_time': averageExecutionTime.inMilliseconds,
      'config': config,
    };
  }
}

class QuantumGate {
  final String id;
  final QuantumGateType type;
  final List<int> targetQubits;
  final List<int> controlQubits;
  final Map<String, dynamic> parameters;
  final List<List<Complex>> matrix;
  final DateTime appliedAt;

  QuantumGate({
    required this.id,
    required this.type,
    required this.targetQubits,
    required this.controlQubits,
    required this.parameters,
    required this.matrix,
    required this.appliedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'target_qubits': targetQubits,
      'control_qubits': controlQubits,
      'parameters': parameters,
      'matrix': matrix.map((row) => row.map((c) => {'real': c.real, 'imag': c.imag}).toList()).toList(),
      'applied_at': appliedAt.toIso8601String(),
    };
  }
}

class MeasurementResult {
  final bool success;
  final String? circuitId;
  final List<int> qubitIndices;
  final MeasurementBasis basis;
  final int shots;
  final List<MeasurementResult> results;
  final DateTime timestamp;
  final QuantumState? measuredState;
  final double? probabilityZero;
  final double? probabilityOne;
  final int? zeroCount;
  final int? oneCount;
  final String? error;

  MeasurementResult({
    required this.success,
    this.circuitId,
    required this.qubitIndices,
    required this.basis,
    required this.shots,
    this.results,
    required this.timestamp,
    this.measuredState,
    this.probabilityZero,
    this.probabilityOne,
    this.zeroCount,
    this.oneCount,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'circuit_id': circuitId,
      'qubit_indices': qubitIndices,
      'basis': basis.name,
      'shots': shots,
      'results': results.map((r) => r.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'measured_state': measuredState?.name,
      'probability_zero': probabilityZero,
      'probability_one': probabilityOne,
      'zero_count': zeroCount,
      'one_count': oneCount,
      'error': error,
    };
  }
}

class QuantumAlgorithm {
  final String id;
  final String name;
  final QuantumAlgorithmType type;
  final String description;
  final String complexity;
  final int requiredQubits;
  final DateTime createdAt;
  final DateTime? lastExecuted;
  int executionCount;
  Duration averageExecutionTime;
  double errorRate;
  final Map<String, dynamic> config;

  QuantumAlgorithm({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.complexity,
    required this.requiredQubits,
    required this.createdAt,
    this.lastExecuted,
    required this.executionCount,
    required this.averageExecutionTime,
    required this.errorRate,
    required this.config,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'description': description,
      'complexity': complexity,
      'required_qubits': requiredQubits,
      'created_at': createdAt.toIso8601String(),
      'last_executed': lastExecuted?.toIso8601String(),
      'execution_count': executionCount,
      'average_execution_time': averageExecutionTime.inMilliseconds,
      'error_rate': errorRate,
      'config': config,
    };
  }
}

class QuantumJob {
  final String id;
  final String algorithmId;
  final String circuitId;
  QuantumJobStatus status;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  Duration executionTime;
  final Map<String, dynamic>? result;
  final String? error;
  final Map<String, dynamic> parameters;
  final Map<String, dynamic> metadata;

  QuantumJob({
    required this.id,
    required this.algorithmId,
    required this.circuitId,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    required this.executionTime,
    this.result,
    this.error,
    required this.parameters,
    required this.metadata,
  });

  bool get success => status == QuantumJobStatus.completed && error == null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'algorithm_id': algorithmId,
      'circuit_id': circuitId,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'execution_time': executionTime.inMilliseconds,
      'result': result,
      'error': error,
      'parameters': parameters,
      'metadata': metadata,
    };
  }
}

class QuantumQubit {
  final String id;
  final int index;
  QuantumState state;
  final Complex amplitude;
  final double phase;
  bool entangled;
  final List<String> entangledWith;
  final List<MeasurementResult> measurementHistory;
  final DateTime createdAt;
  DateTime lastModified;

  QuantumQubit({
    required this.id,
    required this.index,
    required this.state,
    required this.amplitude,
    required this.phase,
    required this.entangled,
    required this.entangledWith,
    required this.measurementHistory,
    required this.createdAt,
    required this.lastModified,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'index': index,
      'state': state.name,
      'amplitude': {'real': amplitude.real, 'imag': amplitude.imag},
      'phase': phase,
      'entangled': entangled,
      'entangled_with': entangledWith,
      'measurement_history': measurementHistory.map((m) => m.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
      'last_modified': lastModified.toIso8601String(),
    };
  }
}

class QuantumAnalytics {
  final int totalCircuits;
  final int totalAlgorithms;
  final int totalJobs;
  final Map<QuantumCircuitType, int> circuitTypeStats;
  final Map<QuantumAlgorithmType, int> algorithmTypeStats;
  final Map<QuantumJobStatus, int> jobStatusStats;
  final double averageCircuitFidelity;
  final Duration averageAlgorithmExecutionTime;
  final double averageQuantumCoherence;
  final DateTime startDate;
  final DateTime endDate;

  QuantumAnalytics({
    required this.totalCircuits,
    required this.totalAlgorithms,
    required this.totalJobs,
    required this.circuitTypeStats,
    required this.algorithmTypeStats,
    required this.jobStatusStats,
    required this.averageCircuitFidelity,
    required this.averageAlgorithmExecutionTime,
    required this.averageQuantumCoherence,
    required this.startDate,
    required this.endDate,
  });
}

class QuantumEvent {
  final QuantumEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  QuantumEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class CircuitResult {
  final bool success;
  final QuantumCircuit? circuit;
  final String? error;

  CircuitResult({
    required this.success,
    this.circuit,
    this.error,
  });
}

class GateResult {
  final bool success;
  final QuantumGate? gate;
  final String? error;

  GateResult({
    required this.success,
    this.gate,
    this.error,
  });
}

class AlgorithmResult {
  final bool success;
  final QuantumJob? job;
  final String? error;

  AlgorithmResult({
    required this.success,
    this.job,
    this.error,
  });
}

class Complex {
  final double real;
  final double imag;

  Complex(this.real, this.imag);

  Map<String, dynamic> toJson() {
    return {
      'real': real,
      'imag': imag,
    };
  }
}

enum QuantumCircuitType {
  general,
  entanglement,
  ghz,
  qft,
  variational,
}

enum QuantumGateType {
  hadamard,
  pauliX,
  pauliY,
  pauliZ,
  phase,
  cnot,
  swap,
  toffoli,
  fredkin,
  controlled_u,
  controlled_phase,
}

enum QuantumState {
  zero,
  one,
  superposition,
}

enum MeasurementBasis {
  computational,
  hadamard,
  x,
  y,
  z,
}

enum QuantumAlgorithmType {
  grover,
  shor,
  qft,
  vqe,
  bernsteinVazirani,
  deutschJozsa,
}

enum QuantumJobStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
}

enum QuantumEventType {
  circuitCreated,
  gateApplied,
  measurementPerformed,
  algorithmCompleted,
  algorithmFailed,
  error,
}
