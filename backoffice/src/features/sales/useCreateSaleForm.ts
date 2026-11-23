import { useEffect, useMemo, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { AxiosError } from 'axios';
import { categoriesApi, clientsApi, productsApi, ventesApi } from '../../lib/api';
import { Product, Vente, VenteCreate } from '../../types';
import { useEntitlement } from '../../hooks/useEntitlement';
import { useAuthStore } from '../../stores/authStore';
import { useTenantContextKey, useTenantStore } from '../../stores/tenantStore';
import { PosCartItem } from './PosProductCatalog';

export const useCreateSaleForm = (isOpen: boolean, onSaleCreated?: (vente: Vente) => void) => {
  const queryClient = useQueryClient();
  const [boutiqueKey, magasinKey] = useTenantContextKey();
  const { currentBoutique, magasins, currentMagasin, isConsolidatedView } = useTenantStore();
  const storeDisplayName = currentBoutique?.company_name || currentBoutique?.name || 'TocManager';
  const user = useAuthStore((s) => s.user);
  const canOverridePrice = ['owner', 'store_admin', 'merchant', 'admin', 'manager'].includes(
    user?.role || ''
  );
  const { hasFeature, openUpgradeForFeature } = useEntitlement();
  const canCreditSales = hasFeature('module_credit_sales');

  const retailMagasins = useMemo(() => magasins.filter((m) => m.is_active && !m.is_warehouse), [magasins]);
  const needsExplicitMagasinSelector = isConsolidatedView || !currentMagasin || currentMagasin.is_warehouse;

  const [targetMagasinId, setTargetMagasinId] = useState<string>('');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [cart, setCart] = useState<PosCartItem[]>([]);
  const [selectedClientId, setSelectedClientId] = useState<string>('');
  const [paymentMethod, setPaymentMethod] = useState<string>('Espèces');
  const [discountAmount, setDiscountAmount] = useState<number>(0);
  const [paidAmount, setPaidAmount] = useState<number>(0);
  const [paidAmountTouched, setPaidAmountTouched] = useState(false);
  const [userEditedPaidAmount, setUserEditedPaidAmount] = useState(false);
  const [notes, setNotes] = useState('');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [completedVente, setCompletedVente] = useState<Vente | null>(null);

  useEffect(() => {
    if (!isOpen) return;
    if (!needsExplicitMagasinSelector && currentMagasin) {
      setTargetMagasinId(currentMagasin.id);
    } else if (retailMagasins.length === 1) {
      setTargetMagasinId(retailMagasins[0].id);
    } else {
      setTargetMagasinId('');
    }
  }, [isOpen, needsExplicitMagasinSelector, currentMagasin, retailMagasins]);

  const effectiveMagasinId = needsExplicitMagasinSelector ? targetMagasinId || undefined : currentMagasin?.id;

  const { data: products = [], isLoading: isLoadingProducts } = useQuery({
    queryKey: ['products', boutiqueKey, effectiveMagasinId || magasinKey, 'pos-avail'],
    queryFn: () => productsApi.getAll({ only_available: true, magasin_id: effectiveMagasinId, limit: 500 }),
    enabled: isOpen,
  });
  const { data: categories = [] } = useQuery({
    queryKey: ['categories', boutiqueKey, magasinKey],
    queryFn: () => categoriesApi.getAll(),
    enabled: isOpen,
  });
  const { data: clients = [] } = useQuery({
    queryKey: ['clients', boutiqueKey, magasinKey],
    queryFn: () => clientsApi.getAll(),
    enabled: isOpen,
  });

  const filteredProducts = useMemo(
    () =>
      products.filter((p) => {
        const matchSearch =
          p.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
          (p.barcode && p.barcode.toLowerCase().includes(searchTerm.toLowerCase()));
        return matchSearch && (selectedCategory === 'all' || p.category_sync_id === selectedCategory);
      }),
    [products, searchTerm, selectedCategory]
  );

  const selectedClient = useMemo(
    () => clients.find((c) => c.sync_id === selectedClientId) || null,
    [clients, selectedClientId]
  );
  const subtotal = useMemo(() => cart.reduce((acc, it) => acc + it.quantity * it.unit_price, 0), [cart]);
  const totalAmount = useMemo(() => Math.max(0, subtotal - (discountAmount || 0)), [subtotal, discountAmount]);
  const effectivePaidAmount = paidAmountTouched ? paidAmount : totalAmount;
  const changeToReturn = effectivePaidAmount > totalAmount ? effectivePaidAmount - totalAmount : 0;
  const debtRemaining = totalAmount > effectivePaidAmount ? totalAmount - effectivePaidAmount : 0;

  const addToCart = (product: Product) => {
    setCart((prev) => {
      const existing = prev.find((item) => item.product.sync_id === product.sync_id);
      if (existing) {
        if (existing.quantity >= product.stock) {
          setErrorMessage(`Stock maximum disponible atteint pour "${product.name}" (${product.stock}).`);
          return prev;
        }
        setErrorMessage(null);
        return prev.map((it) =>
          it.product.sync_id === product.sync_id ? { ...it, quantity: it.quantity + 1 } : it
        );
      }
      if (product.stock <= 0) {
        setErrorMessage(`Le produit "${product.name}" est en rupture de stock.`);
        return prev;
      }
      setErrorMessage(null);
      return [...prev, { product, quantity: 1, unit_price: product.price }];
    });
  };

  const updateQuantity = (productSyncId: string, delta: number) => {
    const target = cart.find((item) => item.product.sync_id === productSyncId);
    if (!target) return;
    const newQty = target.quantity + delta;
    if (newQty > target.product.stock) {
      setErrorMessage(`Stock maximum pour "${target.product.name}" est de ${target.product.stock}.`);
      return;
    }
    setErrorMessage(null);
    setCart((prev) =>
      prev
        .map((it) => (it.product.sync_id === productSyncId ? (newQty > 0 ? { ...it, quantity: newQty } : null) : it))
        .filter(Boolean) as PosCartItem[]
    );
  };

  const resetForm = () => {
    setCart([]);
    setSelectedClientId('');
    setPaymentMethod('Espèces');
    setDiscountAmount(0);
    setPaidAmount(0);
    setPaidAmountTouched(false);
    setUserEditedPaidAmount(false);
    setNotes('');
    setErrorMessage(null);
    setCompletedVente(null);
  };

  const createSaleMutation = useMutation({
    mutationFn: (payload: VenteCreate) => ventesApi.create(payload),
    onSuccess: (newVente) => {
      queryClient.invalidateQueries({ queryKey: ['ventes'] });
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['clients'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
      queryClient.invalidateQueries({ queryKey: ['recent-ventes'] });
      setCompletedVente(newVente);
      if (onSaleCreated) onSaleCreated(newVente);
    },
    onError: (err: AxiosError<{ detail?: unknown }>) => {
      const msg = err.response?.data?.detail || "Une erreur est survenue lors de l'enregistrement de la vente.";
      setErrorMessage(typeof msg === 'string' ? msg : JSON.stringify(msg));
    },
  });

  const handleSubmitSale = () => {
    setErrorMessage(null);
    if (cart.length === 0) return setErrorMessage('Veuillez ajouter au moins un produit au panier.');
    if (needsExplicitMagasinSelector && !effectiveMagasinId) {
      return setErrorMessage('Veuillez sélectionner le point de vente concerné par cette vente.');
    }
    if (paymentMethod === 'Crédit' && !selectedClientId) {
      return setErrorMessage('Une vente à crédit nécessite de sélectionner un client identifié.');
    }
    if (debtRemaining > 0 && !selectedClientId) {
      return setErrorMessage('Paiement partiel : veuillez sélectionner un client pour enregistrer la créance.');
    }
    createSaleMutation.mutate({
      magasin_id: effectiveMagasinId || null,
      client_sync_id: selectedClientId || null,
      client_name: selectedClient?.name || 'Client Occasionnel',
      items: cart.map((item) => ({
        product_sync_id: item.product.sync_id,
        quantity: item.quantity,
        unit_price: item.unit_price,
        cost_price: item.product.cost_price,
        product_name: item.product.name,
      })),
      discount_amount: Number(discountAmount) || 0,
      paid_amount: Number(effectivePaidAmount) || 0,
      payment_method: paymentMethod,
      notes: notes || null,
    });
  };

  const handlePaymentMethodChange = (nextMethod: string) => {
    if (nextMethod === 'Crédit' && !canCreditSales) {
      openUpgradeForFeature(
        'module_credit_sales',
        'Ventes a credit verrouillees',
        'Les ventes a credit et le suivi des creances clients necessitent le forfait Pro.'
      );
      return;
    }
    setPaymentMethod(nextMethod);
    if (nextMethod === 'Crédit' && !userEditedPaidAmount) {
      setPaidAmount(0);
      setPaidAmountTouched(true);
    } else if (nextMethod !== 'Crédit' && !userEditedPaidAmount) {
      setPaidAmountTouched(false);
    }
  };

  return {
    storeDisplayName, magasinName: currentMagasin?.name, retailMagasins, needsExplicitMagasinSelector,
    targetMagasinId, searchTerm, setSearchTerm, selectedCategory, setSelectedCategory,
    cart, setCart, selectedClientId, setSelectedClientId, paymentMethod, discountAmount, setDiscountAmount,
    paidAmount, paidAmountTouched, notes, setNotes, errorMessage, completedVente,
    products, filteredProducts, categories, clients, isLoadingProducts,
    isSubmitting: createSaleMutation.isPending, canCreditSales, canOverridePrice,
    effectivePaidAmount, totalAmount, changeToReturn, debtRemaining,
    addToCart, updateQuantity, resetForm, handleSubmitSale, handlePaymentMethodChange,
    updateUnitPrice: (id: string, unitPrice: number) =>
      setCart((prev) => prev.map((it) => (it.product.sync_id === id ? { ...it, unit_price: Math.max(0, unitPrice) } : it))),
    removeCartItem: (id: string) => setCart((prev) => prev.filter((it) => it.product.sync_id !== id)),
    selectTargetMagasin: (id: string) => { setTargetMagasinId(id); setCart([]); },
    handlePaidAmountChange: (val: number) => { setPaidAmount(val); setPaidAmountTouched(true); setUserEditedPaidAmount(true); },
    handleExactPaidAmount: () => { setPaidAmount(totalAmount); setPaidAmountTouched(true); setUserEditedPaidAmount(true); },
  };
};
