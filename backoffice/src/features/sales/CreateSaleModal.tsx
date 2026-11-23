import React from 'react';
import { ShoppingCart } from 'lucide-react';
import { Vente } from '../../types';
import { Modal } from '../../components/common/Modal';
import { PosProductCatalog } from './PosProductCatalog';
import { PosCartPanel } from './PosCartPanel';
import { SaleSuccessTicket } from './SaleSuccessTicket';
import { useCreateSaleForm } from './useCreateSaleForm';

interface CreateSaleModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSaleCreated?: (vente: Vente) => void;
}

export const CreateSaleModal: React.FC<CreateSaleModalProps> = ({
  isOpen,
  onClose,
  onSaleCreated,
}) => {
  const form = useCreateSaleForm(isOpen, onSaleCreated);

  const handleClose = () => {
    form.resetForm();
    onClose();
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={handleClose}
      title={
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-lg bg-brand-500/10 text-brand-600 dark:text-brand-400 flex items-center justify-center">
            <ShoppingCart className="w-4 h-4" />
          </div>
          <span>Point de Vente & Caisse Back-Office</span>
        </div>
      }
      subtitle="Sélectionnez des articles, gérez les règlements et éditez des tickets de caisse en temps réel."
      maxWidth="max-w-6xl"
    >
      {form.completedVente ? (
        <SaleSuccessTicket
          vente={form.completedVente}
          storeDisplayName={form.storeDisplayName}
          magasinName={form.magasinName}
          onPrint={() => window.print()}
          onNewSale={form.resetForm}
        />
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 pt-2">
          <PosProductCatalog
            products={form.products}
            filteredProducts={form.filteredProducts}
            categories={form.categories}
            cart={form.cart}
            isLoading={form.isLoadingProducts}
            searchTerm={form.searchTerm}
            selectedCategory={form.selectedCategory}
            onSearchChange={form.setSearchTerm}
            onCategoryChange={form.setSelectedCategory}
            onAddToCart={form.addToCart}
          />
          <PosCartPanel
            cart={form.cart}
            clients={form.clients}
            retailMagasins={form.retailMagasins}
            needsExplicitMagasinSelector={form.needsExplicitMagasinSelector}
            targetMagasinId={form.targetMagasinId}
            selectedClientId={form.selectedClientId}
            paymentMethod={form.paymentMethod}
            canCreditSales={form.canCreditSales}
            canOverridePrice={form.canOverridePrice}
            discountAmount={form.discountAmount}
            paidAmount={form.paidAmount}
            paidAmountTouched={form.paidAmountTouched}
            effectivePaidAmount={form.effectivePaidAmount}
            totalAmount={form.totalAmount}
            changeToReturn={form.changeToReturn}
            debtRemaining={form.debtRemaining}
            notes={form.notes}
            errorMessage={form.errorMessage}
            isSubmitting={form.isSubmitting}
            onClearCart={() => form.setCart([])}
            onUpdateQty={form.updateQuantity}
            onUpdateUnitPrice={form.updateUnitPrice}
            onRemoveItem={form.removeCartItem}
            onSelectMagasin={form.selectTargetMagasin}
            onSelectClient={form.setSelectedClientId}
            onPaymentMethodChange={form.handlePaymentMethodChange}
            onDiscountChange={form.setDiscountAmount}
            onPaidAmountChange={form.handlePaidAmountChange}
            onExactPaidAmount={form.handleExactPaidAmount}
            onNotesChange={form.setNotes}
            onCancel={handleClose}
            onSubmit={form.handleSubmitSale}
          />
        </div>
      )}
    </Modal>
  );
};
