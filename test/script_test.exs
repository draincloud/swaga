defmodule ScriptTest do
  use ExUnit.Case

  test "corretly evaluates script" do
    z = 0x7C076FF316692A3D7EB3C3BB0F8B1488CF72E1AFCD929E29307032997A838A3D

    sec =
      Base.decode16!(
        "04887387e452b8eacc4acfde10d9aaf7f6d9a0f975aabb10d006e4da568744d06c61de6d95231cd89026e286df3b6ae4a894a3378e393e93a0f45b666329a0ae34"
      )

    sig =
      Base.decode16!(
        "3045022000eff69ef2b1bd93a66ed5219add4fb51e11a840f404876325a1e8ffe0529a2c022100c7207fee197d27c618aea621406f6bf5ef6fca38681d82b2f06fddbdce6feab601"
      )

    script_pubkey = Script.new([sec, 0xAC])
    script_sig = Script.new([sig])
    combined_script = Script.add(script_sig, script_pubkey)
  end
end
