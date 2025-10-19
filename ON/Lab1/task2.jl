# Sara Żyndul

# Wyrazenie Kahana
K(T) = T(3)*(T(4)/T(3) - T(1)) - T(1)

# Dla kazdego typu zmiennoprzecinkowego wyliczamy wartosc wyrazenia kahana
for T in (Float16, Float32, Float64)
  println(T, "  Kahan = ", K(T), "  eps = ", eps(T))
end