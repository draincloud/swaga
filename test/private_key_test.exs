defmodule PrivateKeyTest do
  use ExUnit.Case

  test "Find the WIF for the private key whose secrets are:" do
    pk = PrivateKey.new(5003)
    wif = PrivateKey.wif(pk, true, true)
    assert wif == "cMahea7zqjxrtgAbB7LSGbcQUr1uX1ojuat9jZodMN8rFTv2sfUK"
    pk = PrivateKey.new(2021 ** 5)
    wif = PrivateKey.wif(pk, false, true)
    assert wif == "91avARGdfge8E4tZfYLoxeJ5sGBdNJQH4kvjpWAxgzczjbCwxic"
    pk = PrivateKey.new(1_481_187_632_463_599)
    wif = PrivateKey.wif(pk, true, false)
    assert wif == "KwDiBf89QgGbjEhKnhXJuH7LrciVrZi3qYjgiuQJv1h8Ytr2S53a"
  end
end
