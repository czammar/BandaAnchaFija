import torch.nn as nn
# ==================
# Regresion logistica multinomial
# ==================
class RegresionMultinomial(nn.Module):
    def __init__(self, input_size, num_classes):
        super(RegresionMultinomial, self).__init__()
        self.linear = nn.Linear(input_size, num_classes)

    def forward(self, x):
        out = self.linear(x)
        return out

# ==================
# Red neuronal de 1 capa escondida con activaciones Sigm
# ==================
class RedNeuronal_Sigm(nn.Module):
    def __init__(self, input_size, num_classes):
        # Permite que la clase  RedNeuronal herede los atributos y metodos de
        # las clases hijas de la clase nn.Module al ser construida
        super(RedNeuronal_Sigm, self).__init__()

        # unidad de capa escondida
        hidden_size = 500

        # funciones de pre-activacion y activacion en capa escondida (linea-sigmoide-lineal)
        self.fc1 = nn.Linear(input_size, hidden_size)
        self.sigmoid = nn.Sigmoid()
        self.fc2 = nn.Linear(hidden_size, num_classes)

    def forward(self, x):
        out = self.fc1(x)
        out = self.sigmoid(out)
        out = self.fc2(out)
        return out

# ==================
# Red neuronal de 1 capa escondida con activaciones ReLU
# ==================
class RedNeuronal_ReLU(nn.Module):
    def __init__(self, input_size, num_classes):
        # Permite que la clase  RedNeuronal herede los atributos y metodos de
        # las clases hijas de la clase nn.Module al ser construida
        super(RedNeuronal_ReLU, self).__init__()

        # unidad de capa escondida
        hidden_size = 500

        # funciones de pre-activacion y activacion en capa escondida (linea-sigmoide-lineal)
        self.fc1 = nn.Linear(input_size, hidden_size)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(hidden_size, num_classes)

    def forward(self, x):
        out = self.fc1(x)
        out = self.relu(out)
        out = self.fc2(out)
        return out 
    
# ==================
# Red neuronal de 3 capas escondidas con activaciones Sigm
# ==================
class RedNeuronal3_Sigm(nn.Module):
    def __init__(self, input_size, num_classes):
        # Permite que la clase  RedNeuronal herede los atributos y metodos de
        # las clases hijas de la clase nn.Module al ser construida
        super(RedNeuronal3_Sigm, self).__init__()

        # unidades de capas escondidas
        hidden_size1, hidden_size2, hidden_size3  = 500, 100, 30

        # funciones de pre-activacion y activacion en capa escondida (linea-sigmoide-lineal)
        self.fc1= nn.Linear(input_size, hidden_size1)
        self.sigmoid = nn.Sigmoid()
        self.fc2 = nn.Linear(hidden_size1, hidden_size2)
        self.fc3 = nn.Linear(hidden_size2, hidden_size3)
        self.fc4 = nn.Linear(hidden_size3, num_classes)

    def forward(self, x):
        out = self.fc1(x)
        out = self.sigmoid(out)
        out = self.fc2(out)
        out = self.sigmoid(out)
        out = self.fc3(out)
        out = self.sigmoid(out)
        out = self.fc4(out)
        return out
    
    
# ==================
# Red neuronal de 3 capas escondidas con activaciones ReLU
# ==================
class RedNeuronal3_ReLU(nn.Module):
    def __init__(self, input_size, num_classes):
        # Permite que la clase  RedNeuronal herede los atributos y metodos de
        # las clases hijas de la clase nn.Module al ser construida
        super(RedNeuronal3_ReLU, self).__init__()

        # unidades de capas escondidas
        hidden_size1, hidden_size2, hidden_size3  = 500, 100, 30

        # funciones de pre-activacion y activacion en capa escondida (linea-sigmoide-lineal)
        self.fc1= nn.Linear(input_size, hidden_size1)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(hidden_size1, hidden_size2)
        self.fc3 = nn.Linear(hidden_size2, hidden_size3)
        self.fc4 = nn.Linear(hidden_size3, num_classes)

    def forward(self, x):
        out = self.fc1(x)
        out = self.relu(out)
        out = self.fc2(out)
        out = self.relu(out)
        out = self.fc3(out)
        out = self.relu(out)
        out = self.fc4(out)
        return out

# ==================
# Red neuronal de 5 capas escondidas con activaciones Sigm
# ==================
class RedNeuronal5_Sigm(nn.Module):
    def __init__(self, input_size, num_classes):
    # Permite que la clase  RedNeuronal herede los atributos y metodos de
    # las clases hijas de la clase nn.Module al ser construida
        super(RedNeuronal5_Sigm, self).__init__()

        # unidades de capas escondidas
        hidden_size1, hidden_size2, hidden_size3,hidden_size4, hidden_size5  = 500, 300, 100, 50, 30

        # funciones de pre-activacion y activacion en capa escondida
        self.fc1, self.sigmoid = nn.Linear(input_size, hidden_size1), nn.Sigmoid()
        self.fc2 = nn.Linear(hidden_size1, hidden_size2)
        self.fc3 = nn.Linear(hidden_size2, hidden_size3)
        self.fc4 = nn.Linear(hidden_size3, hidden_size4)
        self.fc5 = nn.Linear(hidden_size4,  hidden_size5)
        self.fc6 = nn.Linear(hidden_size5, num_classes)

    def forward(self, x):
        out = self.fc1(x)
        out = self.sigmoid(out)
        out = self.fc2(out)
        out = self.sigmoid(out)
        out = self.fc3(out)
        out = self.sigmoid(out)
        out = self.fc4(out)
        out = self.sigmoid(out)
        out = self.fc5(out)
        out = self.sigmoid(out)
        out = self.fc6(out)
        return out

# ==================
# Red neuronal de 5 capas escondidas con activaciones ReLU
# ==================
class RedNeuronal5_ReLU(nn.Module):
    def __init__(self, input_size, num_classes):
    # Permite que la clase  RedNeuronal herede los atributos y metodos de
    # las clases hijas de la clase nn.Module al ser construida
        super(RedNeuronal5_ReLU, self).__init__()

        # unidades de capas escondidas
        hidden_size1, hidden_size2, hidden_size3,hidden_size4, hidden_size5  = 500, 300, 100, 50, 30

        # funciones de pre-activacion y activacion en capa escondida
        self.fc1, self.relu = nn.Linear(input_size, hidden_size1), nn.ReLU()
        self.fc2 = nn.Linear(hidden_size1, hidden_size2)
        self.fc3 = nn.Linear(hidden_size2, hidden_size3)
        self.fc4 = nn.Linear(hidden_size3, hidden_size4)
        self.fc5 = nn.Linear(hidden_size4,  hidden_size5)
        self.fc6 = nn.Linear(hidden_size5, num_classes)

    def forward(self, x):
        out = self.fc1(x)
        out = self.relu(out)
        out = self.fc2(out)
        out = self.relu(out)
        out = self.fc3(out)
        out = self.relu(out)
        out = self.fc4(out)
        out = self.relu(out)
        out = self.fc5(out)
        out = self.relu(out)
        out = self.fc6(out)
        return out