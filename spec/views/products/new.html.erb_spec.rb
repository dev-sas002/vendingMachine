require 'rails_helper'

RSpec.describe "products/new", type: :view do
  before(:each) do
    assign(:product, Product.new(
      name: "MyString",
      available_amount: "",
      price: "",
      seller_id: nil
    ))
  end

  it "renders new product form" do
    render

    assert_select "form[action=?][method=?]", products_path, "post" do

      assert_select "input[name=?]", "product[name]"

      assert_select "input[name=?]", "product[available_amount]"

      assert_select "input[name=?]", "product[price]"

      assert_select "input[name=?]", "product[seller_id_id]"
    end
  end
end
