require 'rails_helper'

RSpec.describe "products/edit", type: :view do
  before(:each) do
    @product = assign(:product, Product.create!(
      name: "MyString",
      available_amount: "",
      price: "",
      seller_id: nil
    ))
  end

  it "renders the edit product form" do
    render

    assert_select "form[action=?][method=?]", product_path(@product), "post" do

      assert_select "input[name=?]", "product[name]"

      assert_select "input[name=?]", "product[available_amount]"

      assert_select "input[name=?]", "product[price]"

      assert_select "input[name=?]", "product[seller_id_id]"
    end
  end
end
