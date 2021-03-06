$LOAD_PATH.unshift File.expand_path('../..', __FILE__)

require 'test_base'

module KillBillIntegrationTests

  class TestInvoicePayment < Base

    def setup
      setup_base
      load_default_catalog

      @account          = create_account(@user, @options)
      @account = get_account(@account.account_id, false, false, @options)
    end

    def teardown
      teardown_base
      end

    def test_external_payment_with_exact_amount
      create_charge(@account.account_id, "7.0", 'USD', 'My first charge', @user, @options)
      create_charge(@account.account_id, "5.0", 'USD', 'My second charge', @user, @options)

      pay_all_unpaid_invoices(@account.account_id, true, "12.0", @user, @options)

      refreshed_account = get_account(@account.account_id, true, true, @options)
      assert_equal(0, refreshed_account.account_balance)
      assert_equal(0, refreshed_account.account_cba)
    end

    def test_external_payment_with_no_specified_amount
      create_charge(@account.account_id, "5.0", 'USD', 'My first charge', @user, @options)
      pay_all_unpaid_invoices(@account.account_id, true, nil, @user, @options)

      refreshed_account = get_account(@account.account_id, true, true, @options)
      assert_equal(0, refreshed_account.account_balance)
      assert_equal(0, refreshed_account.account_cba)
    end


    def test_external_payment_with_lower_amount
      charge1 = create_charge(@account.account_id, "7.0", 'USD', 'My first charge', @user, @options)
      charge2 = create_charge(@account.account_id, "5.0", 'USD', 'My second charge', @user, @options)

      pay_all_unpaid_invoices(@account.account_id, true, "10.0", @user, @options)

      invoice1 = get_invoice_by_id(charge1.invoice_id, @options)
      assert_equal(0, invoice1.balance)

      invoice2 = get_invoice_by_id(charge2.invoice_id, @options)
      assert_equal(2.0, invoice2.balance)

      refreshed_account = get_account(@account.account_id, true, true, @options)
      assert_equal(2.0, refreshed_account.account_balance)
      assert_equal(0, refreshed_account.account_cba)
    end

    def test_external_payment_with_higer_amount
      charge1 = create_charge(@account.account_id, "7.0", 'USD', 'My first charge', @user, @options)
      charge2 = create_charge(@account.account_id, "5.0", 'USD', 'My second charge', @user, @options)

      pay_all_unpaid_invoices(@account.account_id, true, "15.0", @user, @options)

      invoice1 = get_invoice_by_id(charge1.invoice_id, @options)
      assert_equal(0.0, invoice1.balance)

      invoice2 = get_invoice_by_id(charge2.invoice_id, @options)
      assert_equal(0.0, invoice2.balance)

      refreshed_account = get_account(@account.account_id, true, true, @options)
      assert_equal(-3.0, refreshed_account.account_balance)
      assert_equal(3.0, refreshed_account.account_cba)
    end

    def test_payment_with_no_specified_amount
      create_charge(@account.account_id, "5.0", 'USD', 'My first charge', @user, @options)
      pay_all_unpaid_invoices(@account.account_id, true, nil, @user, @options)

      refreshed_account = get_account(@account.account_id, true, true, @options)
      assert_equal(0, refreshed_account.account_balance)
      assert_equal(0, refreshed_account.account_cba)
    end

    def test_payment_with_exact_amount
      create_charge(@account.account_id, "7.0", 'USD', 'My first charge', @user, @options)
      create_charge(@account.account_id, "5.0", 'USD', 'My second charge', @user, @options)

      pay_all_unpaid_invoices(@account.account_id, true, "12.0", @user, @options)

      refreshed_account = get_account(@account.account_id, true, true, @options)
      assert_equal(0, refreshed_account.account_balance)
      assert_equal(0, refreshed_account.account_cba)
    end

    def test_payment_with_lower_amount
      charge1 = create_charge(@account.account_id, "7.0", 'USD', 'My first charge', @user, @options)
      charge2 = create_charge(@account.account_id, "5.0", 'USD', 'My second charge', @user, @options)

      pay_all_unpaid_invoices(@account.account_id, true, "10.0", @user, @options)

      invoice1 = get_invoice_by_id(charge1.invoice_id, @options)
      assert_equal(0, invoice1.balance)

      invoice2 = get_invoice_by_id(charge2.invoice_id, @options)
      assert_equal(2.0, invoice2.balance)

      refreshed_account = get_account(@account.account_id, true, true, @options)
      assert_equal(2.0, refreshed_account.account_balance)
      assert_equal(0, refreshed_account.account_cba)
    end

    def test_payment_with_higher_amount
      charge1 = create_charge(@account.account_id, "7.0", 'USD', 'My first charge', @user, @options)
      charge2 = create_charge(@account.account_id, "5.0", 'USD', 'My second charge', @user, @options)

      pay_all_unpaid_invoices(@account.account_id, true, "15.0", @user, @options)

      invoice1 = get_invoice_by_id(charge1.invoice_id, @options)
      assert_equal(0.0, invoice1.balance)

      invoice2 = get_invoice_by_id(charge2.invoice_id, @options)
      assert_equal(0.0, invoice2.balance)

      # Addition paid amount was used to buy some credit
      refreshed_account = get_account(@account.account_id, true, true, @options)
      assert_equal(-3.0, refreshed_account.account_balance)
      assert_equal(3.0, refreshed_account.account_cba)
    end

    def test_external_payment_with_multiple_partial_adjustments
      charge = create_charge(@account.account_id, '50.0', 'USD', 'My charge', @user, @options)

      pay_all_unpaid_invoices(@account.account_id, true, '50.0', @user, @options)

      account = get_account(@account.account_id, true, true, @options)
      assert_equal(0, account.account_balance)
      assert_equal(0, account.account_cba)

      invoice = get_invoice_by_id(charge.invoice_id, @options)
      invoice_item_id = invoice.items.first.invoice_item_id
      assert_equal(0.0, invoice.balance)

      payment_id = account.payments(@options).first.payment_id

      refund(payment_id, '20.0', [{:invoice_item_id => invoice_item_id, :amount => '20'}], @user, @options)
      invoice = get_invoice_by_id(charge.invoice_id, @options)
      assert_equal(0.0, invoice.balance)
      assert_equal(-20.0, invoice.refund_adj)

      refund(payment_id, '30.0', [{:invoice_item_id => invoice_item_id, :amount => '30'}], @user, @options)
      invoice = get_invoice_by_id(charge.invoice_id, @options)
      assert_equal(0.0, invoice.balance)
      assert_equal(-50.0, invoice.refund_adj)
    end

  end
end
