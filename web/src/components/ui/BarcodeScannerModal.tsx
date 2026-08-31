import React, { useEffect, useRef, useState } from 'react';
import { Html5Qrcode } from 'html5-qrcode';
import { Camera, X, Check, Keyboard, AlertCircle } from 'lucide-react';
import { Modal } from './Modal';

interface BarcodeScannerModalProps {
  isOpen: boolean;
  onClose: () => void;
  onScan: (barcode: string) => void;
}

export const BarcodeScannerModal: React.FC<BarcodeScannerModalProps> = ({
  isOpen,
  onClose,
  onScan,
}) => {
  const [manualCode, setManualCode] = useState<string>('');
  const [scanError, setScanError] = useState<string | null>(null);
  const [isScanning, setIsScanning] = useState<boolean>(false);
  const scannerRef = useRef<Html5Qrcode | null>(null);
  const scannerContainerId = 'barcode-camera-scanner-view';

  useEffect(() => {
    if (!isOpen) {
      stopScanner();
      return;
    }

    // Delay start slightly to let modal DOM render
    const timer = setTimeout(() => {
      startScanner();
    }, 300);

    return () => {
      clearTimeout(timer);
      stopScanner();
    };
  }, [isOpen]);

  const startScanner = async () => {
    try {
      setScanError(null);
      const devices = await Html5Qrcode.getCameras();
      if (!devices || devices.length === 0) {
        setScanError('No camera found on this device. Please use manual entry.');
        return;
      }

      const scanner = new Html5Qrcode(scannerContainerId);
      scannerRef.current = scanner;

      await scanner.start(
        { facingMode: 'environment' },
        {
          fps: 10,
          qrbox: { width: 250, height: 160 },
          aspectRatio: 1.777778,
        },
        (decodedText) => {
          onScan(decodedText);
          stopScanner();
          onClose();
        },
        () => {
          // ignore frame decode errors
        }
      );
      setIsScanning(true);
    } catch (err: any) {
      console.warn('Camera scan initialization failed:', err);
      setScanError('Unable to access camera. Please allow camera permissions or enter barcode manually.');
      setIsScanning(false);
    }
  };

  const stopScanner = () => {
    if (scannerRef.current && isScanning) {
      scannerRef.current
        .stop()
        .then(() => scannerRef.current?.clear())
        .catch((e) => console.warn('Error stopping scanner:', e));
      scannerRef.current = null;
      setIsScanning(false);
    }
  };

  const handleManualSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (manualCode.trim()) {
      onScan(manualCode.trim());
      setManualCode('');
      onClose();
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Scan Product Barcode"
      subtitle="Point your camera at the barcode or enter it manually below"
      maxWidth="md"
    >
      <div className="space-y-4">
        {/* Camera Container */}
        <div className="relative w-full aspect-video bg-black rounded-xl overflow-hidden border border-[#2a2a2a] flex items-center justify-center">
          <div id={scannerContainerId} className="w-full h-full" />
          
          {scanError && (
            <div className="absolute inset-0 bg-[#161616]/95 p-4 flex flex-col items-center justify-center text-center">
              <AlertCircle className="w-8 h-8 text-amber-400 mb-2" />
              <p className="text-xs text-gray-300 max-w-xs">{scanError}</p>
            </div>
          )}

          {/* Scanner Crosshair overlay */}
          {isScanning && !scanError && (
            <div className="absolute inset-0 pointer-events-none flex items-center justify-center">
              <div className="w-64 h-32 border-2 border-blue-500 rounded-lg relative">
                <div className="absolute top-1/2 left-0 right-0 h-0.5 bg-red-500 animate-pulse" />
              </div>
            </div>
          )}
        </div>

        {/* Manual Barcode Input */}
        <form onSubmit={handleManualSubmit} className="pt-2">
          <label className="block text-xs font-semibold text-gray-400 uppercase tracking-wider mb-2">
            Manual Barcode Entry
          </label>
          <div className="flex gap-2">
            <div className="relative flex-1">
              <Keyboard className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="e.g. 4712398471201"
                value={manualCode}
                onChange={(e) => setManualCode(e.target.value)}
                className="w-full pl-9 pr-3 py-2.5 bg-[#1f1f1f] border border-[#2e2e2e] rounded-xl text-sm text-white placeholder-gray-500 focus:outline-none focus:border-blue-500"
                autoFocus
              />
            </div>
            <button
              type="submit"
              disabled={!manualCode.trim()}
              className="px-4 py-2.5 bg-blue-600 hover:bg-blue-500 disabled:opacity-50 text-white text-sm font-semibold rounded-xl flex items-center gap-1.5 transition-colors"
            >
              <Check className="w-4 h-4" />
              <span>Apply</span>
            </button>
          </div>
        </form>
      </div>
    </Modal>
  );
};
