import React, { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  ShoppingCart,
  Search,
  Plus,
  Minus,
  Trash2,
  User,
  CreditCard,
  DollarSign,
  AlertCircle,
  Printer,
  CheckCircle2,
  Package,
  Layers,
  ArrowRight,
  Receipt,
  X,
} from 'lucide-react';
import { productsApi, clientsApi, categoriesApi, ventesApi } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { Product, Client, Vente, VenteCreate } from '../../types';
import { Modal } from '../../components/common/Modal';

interface CartItem {
  product: Product;
  quantity: number;
  unit_price: number;
}

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
  const queryClient = useQueryClient();

  // Search & Filters
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');

  // Cart & Checkout state
  const [cart, setCart] = useState<CartItem[]>([]);
  const [selectedClientId, setSelectedClientId] = useState<string>('');
  const [paymentMethod, setPaymentMethod] = useState<string>('Espèces');
  const [discountAmount, setDiscountAmount] = useState<number>(0);
  const [paidAmount, setPaidAmount] = useState<number>(0);
  const [paidAmountTouched, setPaidAmountTouched] = useState(false);
  const [notes, setNotes] = useState('');
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Success ticket state
  const [completedVente, setCompletedVente] = useState<Vente | null>(null);

  // Queries
  const { data: products = [], isLoading: isLoadingProducts } = useQuery({
    queryKey: ['products'],
    queryFn: () => productsApi.getAll(),
    enabled: isOpen,
  });

  const { data: categories = [] } = useQuery({
    queryKey: ['categories'],
    queryFn: () => categoriesApi.getAll(),
    enabled: isOpen,
  });

  const { data: clients = [] } = useQuery({
    queryKey: ['clients'],
    queryFn: () => clientsApi.getAll(),
    enabled: isOpen,
  });

  // Filtered products
  const filteredProducts = useMemo(() => {
    return products.filter((p) => {
      const matchSearch =
        p.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (p.barcode && p.barcode.toLowerCase().includes(searchTerm.toLowerCase()));
      const matchCat =
        selectedCategory === 'all' || p.category_sync_id === selectedCategory;
      return matchSearch && matchCat;
    });
  }, [products, searchTerm, selectedCategory]);

  // Selected client
  const selectedClient = useMemo(() => {
    return clients.find((c) => c.sync_id === selectedClientId) || null;
  }, [clients, selectedClientId]);

  // Totals
  const subtotal = useMemo(() => {
    return cart.reduce((acc, item) => acc + item.quantity * item.unit_price, 0);
  }, [cart]);

  const totalAmount = useMemo(() => {
    return Math.max(0, subtotal - (discountAmount || 0));
  }, [subtotal, discountAmount]);

  // Default paid amount to total if user hasn't explicitly entered a custom value
  const effectivePaidAmount = paidAmountTouched ? paidAmount : totalAmount;

  const changeToReturn = useMemo(() => {
    return effectivePaidAmount > totalAmount ? effectivePaidAmount - totalAmount : 0;
  }, [effectivePaidAmount, totalAmount]);

  const debtRemaining = useMemo(() => {
    return totalAmount > effectivePaidAmount ? totalAmount - effectivePaidAmount : 0;
  }, [effectivePaidAmount, totalAmount]);

  // Cart operations
  const addToCart = (product: Product) => {
    setCart((prev) => {
      const existing = prev.find((item) => item.product.sync_id === product.sync_id);
      if (existing) {
        if (existing.quantity >= product.stock) {
          setErrorMessage(`Stock maximum disponible atteint pour "${product.name}" (${product.stock}).`);
          return prev;
        }
        setErrorMessage(null);
        return prev.map((item) =>
          item.product.sync_id === product.sync_id
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
      } else {
        if (product.stock <= 0) {
          setErrorMessage(`Le produit "${product.name}" est en rupture de stock.`);
          return prev;
        }
        setErrorMessage(null);
        return [...prev, { product, quantity: 1, unit_price: product.price }];
      }
    });
  };

  const updateQuantity = (productSyncId: string, delta: number) => {
    setCart((prev) => {
      return prev
        .map((item) => {
          if (item.product.sync_id === productSyncId) {
            const newQty = item.quantity + delta;
            if (newQty > item.product.stock) {
              setErrorMessage(`Stock maximum pour "${item.product.name}" est de ${item.product.stock}.`);
              return item;
            }
            return newQty > 0 ? { ...item, quantity: newQty } : null;
          }
          return item;
        })
        .filter(Boolean) as CartItem[];
    });
    setErrorMessage(null);
  };

  const removeFromCart = (productSyncId: string) => {
    setCart((prev) => prev.filter((item) => item.product.sync_id !== productSyncId));
  };

  const resetForm = () => {
    setCart([]);
    setSelectedClientId('');
    setPaymentMethod('Espèces');
    setDiscountAmount(0);
    setPaidAmount(0);
    setPaidAmountTouched(false);
    setNotes('');
    setErrorMessage(null);
    setCompletedVente(null);
  };

  // Mutation
  const createSaleMutation = useMutation({
    mutationFn: (payload: VenteCreate) => ventesApi.create(payload),
    onSuccess: (newVente) => {
      queryClient.invalidateQueries({ queryKey: ['ventes'] });
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['clients'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard'] });
      setCompletedVente(newVente);
      if (onSaleCreated) {
        onSaleCreated(newVente);
      }
    },
    onError: (err: any) => {
      const msg = err.response?.data?.detail || "Une erreur est survenue lors de l'enregistrement de la vente.";
      setErrorMessage(typeof msg === 'string' ? msg : JSON.stringify(msg));
    },
  });

  const handleSubmitSale = () => {
    setErrorMessage(null);

    if (cart.length === 0) {
      setErrorMessage('Veuillez ajouter au moins un produit au panier.');
      return;
    }

    if (paymentMethod === 'À crédit' && !selectedClientId) {
      setErrorMessage('Une vente à crédit nécessite de sélectionner un client identifié.');
      return;
    }

    if (debtRemaining > 0 && !selectedClientId) {
      setErrorMessage('Paiement partiel : veuillez sélectionner un client pour enregistrer la créance.');
      return;
    }

    const payload: VenteCreate = {
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
    };

    createSaleMutation.mutate(payload);
  };

  const handlePrintReceipt = () => {
    window.print();
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={() => {
        resetForm();
        onClose();
      }}
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
      {completedVente ? (
        /* Ecran de succès avec ticket de caisse */
        <div className="space-y-6 py-4">
          <div className="text-center space-y-2">
            <div className="w-16 h-16 bg-emerald-100 dark:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 rounded-full flex items-center justify-center mx-auto">
              <CheckCircle2 className="w-10 h-10" />
            </div>
            <h3 className="text-xl font-extrabold text-slate-900 dark:text-white">
              Vente enregistrée avec succès !
            </h3>
            <p className="text-sm text-slate-500 dark:text-slate-400">
              Ticket N° <span className="font-mono font-bold text-brand-600 dark:text-brand-400">{completedVente.ticket_number}</span>
            </p>
          </div>

          {/* Ticket preview card */}
          <div className="max-w-md mx-auto bg-slate-50 dark:bg-dark-700 p-6 rounded-2xl border border-slate-200 dark:border-dark-600 space-y-4 font-mono text-xs text-slate-700 dark:text-slate-300">
            <div className="text-center border-b border-dashed border-slate-300 dark:border-dark-500 pb-3">
              <h4 className="font-bold text-sm text-slate-900 dark:text-white uppercase tracking-wider">
                TOCMANAGER - REÇU DE CAISSE
              </h4>
              <p className="text-slate-500 mt-1">{formatDateTime(completedVente.created_at)}</p>
              <p className="text-slate-500">Client : {completedVente.client_name || 'Occasionnel'}</p>
              <p className="text-slate-500">Mode : {completedVente.payment_method}</p>
            </div>

            <div className="divide-y divide-dashed divide-slate-200 dark:divide-dark-600">
              {completedVente.items.map((it, idx) => (
                <div key={idx} className="py-2 flex justify-between">
                  <div>
                    <span className="font-bold">{it.product_name}</span>
                    <div className="text-[11px] text-slate-500">
                      {it.quantity} x {formatFCFA(it.unit_price)}
                    </div>
                  </div>
                  <span className="font-bold">{formatFCFA(it.total)}</span>
                </div>
              ))}
            </div>

            <div className="border-t border-dashed border-slate-300 dark:border-dark-500 pt-3 space-y-1.5 text-right font-sans">
              {completedVente.discount_amount > 0 && (
                <div className="flex justify-between text-slate-500">
                  <span>Remise accordée :</span>
                  <span>-{formatFCFA(completedVente.discount_amount)}</span>
                </div>
              )}
              <div className="flex justify-between text-sm font-extrabold text-slate-900 dark:text-white">
                <span>TOTAL NET :</span>
                <span className="text-brand-600 dark:text-brand-400">{formatFCFA(completedVente.total_amount)}</span>
              </div>
              <div className="flex justify-between text-slate-500">
                <span>Montant reçu :</span>
                <span>{formatFCFA(completedVente.paid_amount)}</span>
              </div>
              {completedVente.paid_amount > completedVente.total_amount && (
                <div className="flex justify-between font-bold text-emerald-600">
                  <span>Monnaie rendue :</span>
                  <span>{formatFCFA(completedVente.paid_amount - completedVente.total_amount)}</span>
                </div>
              )}
              {completedVente.paid_amount < completedVente.total_amount && (
                <div className="flex justify-between font-bold text-amber-600">
                  <span>Reste à payer (Dette) :</span>
                  <span>{formatFCFA(completedVente.total_amount - completedVente.paid_amount)}</span>
                </div>
              )}
            </div>
          </div>

          <div className="flex justify-center gap-3 pt-2">
            <button
              onClick={handlePrintReceipt}
              className="btn-toc btn-outline flex items-center gap-2"
            >
              <Printer className="w-4 h-4" />
              <span>Imprimer le ticket</span>
            </button>
            <button
              onClick={resetForm}
              className="btn-toc btn-primary flex items-center gap-2"
            >
              <ShoppingCart className="w-4 h-4" />
              <span>Nouvelle Vente</span>
            </button>
          </div>
        </div>
      ) : (
        /* Ecran principal du Point de Vente */
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 pt-2">
          {/* Colonne de Gauche : Catalogue et Sélection de Produits (7 cols) */}
          <div className="lg:col-span-7 space-y-4">
            {/* Search & Categories */}
            <div className="space-y-3">
              <div className="relative">
                <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type="text"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  placeholder="Rechercher par nom de produit ou code-barres..."
                  className="input-toc pl-9 text-sm"
                  autoFocus
                />
              </div>

              {/* Category Pills */}
              <div className="flex items-center gap-1.5 overflow-x-auto pb-1 scrollbar-thin">
                <button
                  onClick={() => setSelectedCategory('all')}
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all whitespace-nowrap ${
                    selectedCategory === 'all'
                      ? 'bg-brand-600 text-white shadow-sm'
                      : 'bg-slate-100 dark:bg-dark-700 text-slate-600 dark:text-slate-400 hover:bg-slate-200'
                  }`}
                >
                  Tous ({products.length})
                </button>
                {categories.map((c) => (
                  <button
                    key={c.sync_id}
                    onClick={() => setSelectedCategory(c.sync_id)}
                    className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all whitespace-nowrap ${
                      selectedCategory === c.sync_id
                        ? 'bg-brand-600 text-white shadow-sm'
                        : 'bg-slate-100 dark:bg-dark-700 text-slate-600 dark:text-slate-400 hover:bg-slate-200'
                    }`}
                  >
                    {c.name}
                  </button>
                ))}
              </div>
            </div>

            {/* Product Grid */}
            <div className="h-[380px] overflow-y-auto pr-1 grid grid-cols-2 sm:grid-cols-3 gap-3">
              {isLoadingProducts ? (
                <div className="col-span-full text-center py-12 text-slate-400 text-sm">
                  Chargement des produits...
                </div>
              ) : filteredProducts.length > 0 ? (
                filteredProducts.map((p) => {
                  const isInCart = cart.find((it) => it.product.sync_id === p.sync_id);
                  const isOutOfStock = p.stock <= 0;

                  return (
                    <button
                      key={p.sync_id}
                      onClick={() => !isOutOfStock && addToCart(p)}
                      disabled={isOutOfStock}
                      className={`text-left p-3 rounded-2xl border transition-all flex flex-col justify-between relative group ${
                        isOutOfStock
                          ? 'opacity-40 bg-slate-50 dark:bg-dark-800/50 border-slate-200 dark:border-dark-700 cursor-not-allowed'
                          : isInCart
                          ? 'bg-brand-50/50 dark:bg-brand-950/20 border-brand-400 dark:border-brand-500 shadow-sm'
                          : 'bg-white dark:bg-dark-700/60 border-slate-200/80 dark:border-dark-600 hover:border-brand-300 dark:hover:border-brand-500 hover:shadow-md'
                      }`}
                    >
                      {isInCart && (
                        <span className="absolute top-2 right-2 w-5 h-5 rounded-full bg-brand-600 text-white text-[10px] font-extrabold flex items-center justify-center shadow">
                          {isInCart.quantity}
                        </span>
                      )}
                      <div className="flex gap-2.5 items-start">
                        {p.image_path ? (
                          <img
                            src={p.image_path}
                            alt={p.name}
                            className="w-10 h-10 rounded-xl object-cover border border-slate-200 dark:border-dark-600 shrink-0 shadow-2xs"
                          />
                        ) : null}
                        <div className="min-w-0 flex-1">
                          <h5 className="font-bold text-xs text-slate-900 dark:text-white line-clamp-2 leading-tight">
                            {p.name}
                          </h5>
                          <div className="mt-1 flex items-center gap-1.5">
                            <span
                              className={`text-[10px] font-bold px-1.5 py-0.5 rounded-md ${
                                p.stock > 5
                                  ? 'bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400'
                                  : p.stock > 0
                                  ? 'bg-amber-50 dark:bg-amber-500/10 text-amber-600 dark:text-amber-400'
                                  : 'bg-red-50 dark:bg-red-500/10 text-red-600 dark:text-red-400'
                              }`}
                            >
                              Stock: {p.stock} {p.unit || 'pièce'}
                            </span>
                          </div>
                        </div>
                      </div>

                      <div className="mt-3 pt-2 border-t border-slate-100 dark:border-dark-600 flex items-center justify-between">
                        <span className="font-extrabold text-sm text-brand-600 dark:text-brand-400 font-mono">
                          {formatFCFA(p.price)}
                        </span>
                        <div className="w-6 h-6 rounded-lg bg-brand-50 dark:bg-brand-500/10 text-brand-600 dark:text-brand-400 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                          <Plus className="w-3.5 h-3.5" />
                        </div>
                      </div>
                    </button>
                  );
                })
              ) : (
                <div className="col-span-full text-center py-12 text-slate-400 text-sm">
                  Aucun produit ne correspond à cette recherche.
                </div>
              )}
            </div>
          </div>

          {/* Colonne de Droite : Panier & Encaissement (5 cols) */}
          <div className="lg:col-span-5 bg-slate-50/80 dark:bg-dark-750 p-4 rounded-2xl border border-slate-200 dark:border-dark-600 flex flex-col justify-between space-y-4">
            <div className="space-y-4">
              {/* Header Panier */}
              <div className="flex items-center justify-between pb-2 border-b border-slate-200 dark:border-dark-600">
                <span className="font-bold text-sm text-slate-900 dark:text-white flex items-center gap-1.5">
                  <ShoppingCart className="w-4 h-4 text-brand-500" />
                  Panier ({cart.reduce((sum, it) => sum + it.quantity, 0)})
                </span>
                {cart.length > 0 && (
                  <button
                    onClick={() => setCart([])}
                    className="text-xs text-red-500 hover:text-red-700 font-semibold"
                  >
                    Vider le panier
                  </button>
                )}
              </div>

              {/* Items List */}
              <div className="max-h-44 overflow-y-auto space-y-2 pr-1">
                {cart.length === 0 ? (
                  <div className="text-center py-8 text-slate-400 text-xs flex flex-col items-center gap-2">
                    <Package className="w-8 h-8 opacity-40 text-slate-400" />
                    <span>Cliquez sur des articles pour remplir le panier</span>
                  </div>
                ) : (
                  cart.map((item) => (
                    <div
                      key={item.product.sync_id}
                      className="bg-white dark:bg-dark-700 p-2.5 rounded-xl border border-slate-200/80 dark:border-dark-600 flex items-center justify-between gap-2 shadow-xs"
                    >
                      <div className="min-w-0 flex-1">
                        <p className="font-bold text-xs text-slate-900 dark:text-white truncate">
                          {item.product.name}
                        </p>
                        <p className="text-[11px] text-slate-500 font-mono">
                          {formatFCFA(item.unit_price)} × {item.quantity} = {formatFCFA(item.quantity * item.unit_price)}
                        </p>
                      </div>

                      <div className="flex items-center gap-1.5">
                        <button
                          onClick={() => updateQuantity(item.product.sync_id, -1)}
                          className="w-6 h-6 rounded-md bg-slate-100 dark:bg-dark-600 text-slate-600 dark:text-slate-300 flex items-center justify-center hover:bg-slate-200"
                        >
                          <Minus className="w-3 h-3" />
                        </button>
                        <span className="w-6 text-center font-bold text-xs text-slate-900 dark:text-white font-mono">
                          {item.quantity}
                        </span>
                        <button
                          onClick={() => updateQuantity(item.product.sync_id, 1)}
                          className="w-6 h-6 rounded-md bg-slate-100 dark:bg-dark-600 text-slate-600 dark:text-slate-300 flex items-center justify-center hover:bg-slate-200"
                        >
                          <Plus className="w-3 h-3" />
                        </button>
                        <button
                          onClick={() => removeFromCart(item.product.sync_id)}
                          className="w-6 h-6 rounded-md text-red-400 hover:text-red-600 flex items-center justify-center ml-1"
                        >
                          <Trash2 className="w-3 h-3" />
                        </button>
                      </div>
                    </div>
                  ))
                )}
              </div>

              {/* Client Selection */}
              <div className="space-y-1.5 pt-2 border-t border-slate-200 dark:border-dark-600">
                <label className="text-xs font-bold text-slate-700 dark:text-slate-300 flex items-center gap-1">
                  <User className="w-3 h-3 text-brand-500" />
                  Client
                </label>
                <select
                  value={selectedClientId}
                  onChange={(e) => setSelectedClientId(e.target.value)}
                  className="input-toc text-xs py-1.5"
                >
                  <option value="">Client Occasionnel (Comptoir)</option>
                  {clients.map((c) => (
                    <option key={c.sync_id} value={c.sync_id}>
                      {c.name} {c.balance > 0 ? `(Dette: ${formatFCFA(c.balance)})` : ''}
                    </option>
                  ))}
                </select>
              </div>

              {/* Mode de règlement & Remise */}
              <div className="grid grid-cols-2 gap-2">
                <div className="space-y-1">
                  <label className="text-[11px] font-bold text-slate-700 dark:text-slate-300">
                    Mode Paiement
                  </label>
                  <select
                    value={paymentMethod}
                    onChange={(e) => setPaymentMethod(e.target.value)}
                    className="input-toc text-xs py-1.5"
                  >
                    <option value="Espèces">Espèces</option>
                    <option value="Wave">Wave</option>
                    <option value="Orange Money">Orange Money</option>
                    <option value="Moov Money">Moov Money</option>
                    <option value="Carte Bancaire">Carte Bancaire</option>
                    <option value="À crédit">À crédit</option>
                  </select>
                </div>

                <div className="space-y-1">
                  <label className="text-[11px] font-bold text-slate-700 dark:text-slate-300">
                    Remise (FCFA)
                  </label>
                  <input
                    type="number"
                    min="0"
                    value={discountAmount || ''}
                    onChange={(e) => setDiscountAmount(Number(e.target.value) || 0)}
                    placeholder="0"
                    className="input-toc text-xs py-1.5 font-mono"
                  />
                </div>
              </div>

              {/* Montant Reçu */}
              <div className="space-y-1">
                <div className="flex justify-between items-center text-[11px] font-bold text-slate-700 dark:text-slate-300">
                  <span>Montant Reçu (FCFA)</span>
                  <button
                    type="button"
                    onClick={() => {
                      setPaidAmount(totalAmount);
                      setPaidAmountTouched(true);
                    }}
                    className="text-brand-600 hover:underline text-[10px]"
                  >
                    Montant exact
                  </button>
                </div>
                <input
                  type="number"
                  min="0"
                  value={paidAmountTouched ? paidAmount : totalAmount}
                  onChange={(e) => {
                    setPaidAmount(Number(e.target.value) || 0);
                    setPaidAmountTouched(true);
                  }}
                  className="input-toc text-sm py-1.5 font-mono font-bold"
                />
              </div>

              {/* Rendu monnaie ou Dette */}
              {effectivePaidAmount > totalAmount && (
                <div className="p-2 rounded-xl bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-200 dark:border-emerald-500/20 flex justify-between items-center text-xs text-emerald-700 dark:text-emerald-400 font-bold">
                  <span>Monnaie à rendre :</span>
                  <span className="font-mono text-sm">{formatFCFA(changeToReturn)}</span>
                </div>
              )}
              {debtRemaining > 0 && (
                <div className="p-2 rounded-xl bg-amber-50 dark:bg-amber-500/10 border border-amber-200 dark:border-amber-500/20 flex justify-between items-center text-xs text-amber-700 dark:text-amber-400 font-bold">
                  <span>Solde restant (Créance) :</span>
                  <span className="font-mono text-sm">{formatFCFA(debtRemaining)}</span>
                </div>
              )}

              {errorMessage && (
                <div className="p-2.5 rounded-xl bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20 flex items-start gap-2 text-xs text-red-600 dark:text-red-400 font-medium">
                  <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                  <span>{errorMessage}</span>
                </div>
              )}
            </div>

            {/* Total Footer & Actions */}
            <div className="pt-3 border-t border-slate-200 dark:border-dark-600 space-y-3">
              <div className="flex justify-between items-baseline">
                <span className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase">
                  Total à encaisser :
                </span>
                <span className="text-xl font-extrabold text-slate-900 dark:text-white font-mono">
                  {formatFCFA(totalAmount)}
                </span>
              </div>

              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={() => {
                    resetForm();
                    onClose();
                  }}
                  className="btn-toc btn-outline flex-1 py-2 text-xs"
                >
                  Annuler
                </button>
                <button
                  type="button"
                  onClick={handleSubmitSale}
                  disabled={cart.length === 0 || createSaleMutation.isPending}
                  className="btn-toc btn-primary flex-2 py-2 text-xs font-extrabold flex items-center justify-center gap-1.5 shadow-md shadow-brand-500/20"
                >
                  <Receipt className="w-4 h-4" />
                  <span>{createSaleMutation.isPending ? 'Encaissement...' : 'Valider & Encaisser'}</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </Modal>
  );
};
