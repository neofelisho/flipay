defmodule FlipayWeb.QuoteControllerTest do
  use FlipayWeb.ConnCase

  import Mock

  @create_attrs %{
    email: "some@email",
    password: "some_password",
    password_confirmation: "some_password"
  }

  @sign_in_attrs %{email: "some@email", password: "some_password"}
  @coinbase "coinbase"
  @coinbase_pro "coinbase_pro"
  @hitbtc "hitbtc"

  def fixture(:user) do
    {:ok, user} = Accounts.create_user(@create_attrs)
    user
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "show best rate" do
    test "unauthenticated user", %{conn: conn} do
      conn = get(conn, Routes.quote_path(conn, :show, @coinbase))
      assert conn.status == 401
      assert conn.resp_body == "{\"error\":\"unauthenticated\"}"
    end

    test "best buying rate from coinbase", %{conn: conn} do
      with_mock Flipay.Exchanges.Coinbase,
        get_order_book: fn _, _ ->
          {:ok, ~s(
            {
              "bids": [
                ["2000", "10", "1"],
                ["1900", "1", "1"]
              ],
              "asks": [
                ["2000", "2", "1"],
                ["2100", "1", "1"]
              ]
            }
          )}
        end do
        conn_login = login(conn)

        conn_login =
          get(
            conn_login,
            Routes.quote_path(conn, :show, @coinbase,
              input_asset: "USD",
              input_amount: "5050",
              output_asset: "BTC"
            )
          )

        assert %{"best_rate" => best_rate} = json_response(conn_login, 200)
        assert Decimal.equal?(best_rate, "2.5")
      end
    end

    test "best selling rate from coinbase_pro", %{conn: conn} do
      with_mock Flipay.Exchanges.Coinbase,
        get_order_book: fn _, _ ->
          {:ok, ~s(
            {
              "bids": [
                ["2000", "5", "1"],
                ["1900", "10", "1"]
              ],
              "asks": [
                ["2000", "2", "1"],
                ["2100", "1", "1"]
              ]
            }
          )}
        end do
        conn_login = login(conn)

        conn_login =
          get(
            conn_login,
            Routes.quote_path(conn, :show, @coinbase_pro,
              input_asset: "ETH",
              input_amount: "8.9",
              output_asset: "USD"
            )
          )

        assert %{"best_rate" => best_rate} = json_response(conn_login, 200)
        assert Decimal.equal?(best_rate, "17410")
      end
    end

    test "unimplemented hitbtc exchange", %{conn: conn} do
      conn_login = login(conn)

      conn_login =
        get(
          conn_login,
          Routes.quote_path(conn, :show, @hitbtc,
            input_asset: "USD",
            input_amount: "2000",
            output_asset: "ETH"
          )
        )

      assert %{"detail" => "Not Found"} = json_response(conn_login, 404)["errors"]
    end

    test "input amount over quotes", %{conn: conn} do
      with_mock Flipay.Exchanges.Coinbase,
        get_order_book: fn _, _ ->
          {:ok, ~s(
            {
              "bids": [
                ["2000", "10", "1"],
                ["1900", "1", "1"]
              ],
              "asks": [
                ["2000", "2", "1"],
                ["2100", "1", "1"]
              ]
            }
          )}
        end do
        conn_login = login(conn)

        conn_login =
          get(
            conn_login,
            Routes.quote_path(conn, :show, @coinbase_pro,
              input_asset: "BTC",
              input_amount: "12",
              output_asset: "USD"
            )
          )

        assert %{"error" => reason} = json_response(conn_login, 200)
        assert reason == "not enough quotes for trading"
      end
    end

    test "no quotes from exchange", %{conn: conn} do
      with_mock Flipay.Exchanges.Coinbase,
        get_order_book: fn _, _ ->
          {:ok, ~s(
            {
              "bids": [],
              "asks": []
            }
          )}
        end do
        conn_login = login(conn)

        conn_login =
          get(
            conn_login,
            Routes.quote_path(conn, :show, @coinbase_pro,
              input_asset: "BTC",
              input_amount: "1",
              output_asset: "USD"
            )
          )

        assert %{"error" => reason} = json_response(conn_login, 200)
        assert reason == "no quotes from exchange"
      end
    end

    test "unsupported asset type", %{conn: conn} do
      conn_login = login(conn)

      conn_login =
        get(
          conn_login,
          Routes.quote_path(conn, :show, @coinbase_pro,
            input_asset: "BTC",
            input_amount: "1",
            output_asset: "JPY"
          )
        )

      assert %{"error" => reason} = json_response(conn_login, 400)
      assert reason == "unsupported asset type"
    end

    test "unexpected excpetion", %{conn: conn} do
      with_mock Flipay.BestRateFinder, find: fn _ -> {:error, :unexpected} end do
        conn_login = login(conn)

        conn_login =
          get(
            conn_login,
            Routes.quote_path(conn, :show, @coinbase_pro,
              input_asset: "ETH",
              input_amount: "1",
              output_asset: "USD"
            )
          )

        assert %{"error" => reason} = json_response(conn_login, 500)
        assert reason == "unexpected error"
      end
    end
  end

  defp login(conn) do
    post(conn, Routes.user_path(conn, :create), user: @create_attrs)

    conn_sign_in =
      post(conn, Routes.user_path(conn, :sign_in),
        email: @sign_in_attrs.email,
        password: @sign_in_attrs.password
      )

    %{"jwt" => jwt} = json_response(conn_sign_in, 200)

    Plug.Conn.put_req_header(conn, "authorization", "Bearer #{jwt}")
  end
end
