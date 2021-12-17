pragma solidity >=0.8.0;
// SPDX-License-Identifier: Apache-2.0

interface TRC20_Interface {

    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function transfer(address direccion, uint cantidad) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function decimals() external view returns(uint);
}

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        uint c = a - b;

        return c;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);

        return c;
    }

}

contract Context {

  constructor () { }

  function _msgSender() internal view returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view returns (bytes memory) {
    this; 
    return msg.data;
  }
}

contract Ownable is Context {
  address payable public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor(){
    owner = payable(_msgSender());
  }
  modifier onlyOwner() {
    if(_msgSender() != owner)revert();
    _;
  }
  function transferOwnership(address payable newOwner) public onlyOwner {
    if(newOwner == address(0))revert();
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Admin is Context, Ownable{
  mapping (address => bool) public admin;

  event NewAdmin(address indexed admin);
  event AdminRemoved(address indexed admin);

  constructor(){
    admin[_msgSender()] = true;
  }

  modifier onlyAdmin() {
    if(!admin[_msgSender()])revert();
    _;
  }

  function makeNewAdmin(address payable _newadmin) public onlyOwner {
    if(_newadmin == address(0))revert();
    emit NewAdmin(_newadmin);
    admin[_newadmin] = true;
  }

  function makeRemoveAdmin(address payable _oldadmin) public onlyOwner {
    if(_oldadmin == address(0))revert();
    emit AdminRemoved(_oldadmin);
    admin[_oldadmin] = false;
  }

}

contract UnilevelSystem is Context, Admin{
  using SafeMath for uint256;

  address token = 0x55d398326f99059fF775485246999027B3197955;

  TRC20_Interface USDT_Contract = TRC20_Interface(token);

  struct Deposito {
    uint256 inicio;
    uint256 amount;
    bool pasivo;
  }

  struct Investor {
    bool registered;
    uint256 membership;
    uint256 balanceRef;
    uint256 balanceSal;
    uint256 totalRef;
    uint256 invested;
    uint256 paidAt;
    uint256 amount;
    uint256 withdrawn;
    uint256 directos;
    string data;
    Deposito[] depositos;
    uint256 blokesDirectos;
  }

  uint256 public MIN_RETIRO = 30 * 10**18;
  uint256 public MIN_RETIRO_interno;

  uint256 public PRECIO_BLOCK = 50 * 10**18;

  address public tokenPricipal = token;

  uint256 public inversiones = 1;
  uint256[] public primervez = [70, 0, 0, 0, 0];
  uint256[] public porcientos = [0, 0, 0, 0, 0];
  uint256[] public porcientosSalida = [10, 4, 3, 2, 1];

  uint256[] public plans = [0, 50*10**18, 100*10**18, 250*10**18, 500*10**18, 1000*10**18, 2500*10**18, 5000*10**18, 10000*10**18];
  bool[] public active = [false, true, true, true, true, true, true, true, true];

  uint256[] public gananciasRango = [20*10**18, 50*10**18, 200*10**18, 500*10**18, 1200*10**18, 6000*10**18, 15000*10**18, 50000*10**18 ];
  uint256[] public puntosRango = [1500*10**18, 5000*10**18, 20000*10**18, 50000*10**18, 120000*10**18, 600000*10**18, 1500000*10**18, 5000000*10**18];

  bool public onOffWitdrawl = true;

  uint256 public duracionMembership = 365;

  uint256 public dias = 200;
  uint256 public unidades = 86400;

  uint256 public porcent = 240;

  uint256 public porcentPuntosBinario = 5;

  uint256 public descuento = 95;
  uint256 public personas = 2;

  uint256 public totalInvestors = 1;
  uint256 public totalInvested;
  uint256 public totalRefRewards;
  uint256 public totalRefWitdrawl;

  mapping (address => Investor) public investors;
  mapping (address => address) public padre;
  mapping (uint256 => address) public idToAddress;
  mapping (address => uint256) public addressToId;
  mapping (address => bool[]) public rangoReclamado;
  
  uint256 public lastUserId = 1;

  address[] public walletFee = [0x0556a260b9ef10756bc2Df281168697f353d1E8E];
  uint256[] public valorFee = [100];
  uint256 public precioRegistro = 0 * 10**18;
  uint256 public activerFee = 1;
  // 0 desactivada total | 1 activa 5% fee retiro | 2 activa fee retiro y precio de registro

  address[] public wallet = [0x4490566647735e8cBCe0ce96efc8FB91c164859b, 0xe201933cA7B5aF514A1b0119bBC1072a066C06df, 0xe2283cB00B9c32727941728bEDe372005c6ca311, 0x763EB0A2A2925c45927DbF6432f191fc66fbCfa8, 0xDEFf65e4BCF19A52B0DB33E57B7Ce262Fd5dB53F, 0x8A6AC002b64bBba26e746D97d4050e71240B30B0, 0x0bddC342f66F46968A15bD1c16DBEFA5B63a1588];
  uint256[] public valor = [6, 5, 2, 2, 2, 2, 47];

  constructor() {

    Investor storage usuario = investors[owner];

    usuario.registered = true;
    usuario.membership = block.timestamp + duracionMembership*unidades*1000000000000000000;

    rangoReclamado[_msgSender()] = [false,false,false,false,false,false,false];

    idToAddress[0] = _msgSender();
    addressToId[_msgSender()] = 0;

  }

  function setInversiones(uint256 _numerodeinverionessinganancia) public onlyOwner returns(uint256){
    inversiones = _numerodeinverionessinganancia;
    return _numerodeinverionessinganancia;
  }

  function setPrecioRegistro(uint256 _precio) public onlyOwner returns(bool){
    precioRegistro = _precio;
    return true;
  }

  function setDescuento(uint256 _descuento) public onlyOwner returns(bool){
    descuento = _descuento;
    return true;
  }

  function setWalletstransfers(address[] memory _wallets, uint256[] memory _valores) public onlyOwner returns(bool){

    wallet = _wallets;
    valor = _valores;

    return true;

  }

  function setWalletFee(address[] memory _wallet, uint256[] memory _fee , uint256 _activerFee ) public onlyOwner returns(bool){
    walletFee = _wallet;
    valorFee = _fee;
    activerFee = _activerFee;
    return true;
  }

  function setPuntosPorcentajeBinario(uint256 _porcentaje) public onlyOwner returns(uint256){

    porcentPuntosBinario = _porcentaje;

    return _porcentaje;
  }

  function setMIN_RETIRO(uint256 _min) public onlyOwner returns(uint256){

    MIN_RETIRO = _min;

    return _min;

  }

  function ChangeTokenPrincipal(address _tokenTRC20) public onlyOwner returns (bool){

    USDT_Contract = TRC20_Interface(_tokenTRC20);

    tokenPricipal = _tokenTRC20;

    return true;

  }

  function setstate() public view  returns(uint256 Investors,uint256 Invested,uint256 RefRewards){
      return (totalInvestors, totalInvested, totalRefRewards);
  }
  
  function tiempo() public view returns (uint256){
     return dias.mul(unidades);
  }

  function setPorcientos(uint256 _nivel, uint256 _value) public onlyOwner returns(uint256[] memory){

    porcientos[_nivel] = _value;

    return porcientos;

  }

  function setPorcientosSalida(uint256 _nivel, uint256 _value) public onlyOwner returns(uint256[] memory){

    porcientosSalida[_nivel] = _value;

    return porcientosSalida;

  }

  function setPrimeravezPorcientos(uint256 _nivel, uint256 _value) public onlyOwner returns(uint256[] memory){

    primervez[_nivel] = _value;

    return primervez;

  }

  function plansLength() public view returns(uint8){
    
    return uint8(plans.length);
  }

  function setPlansAll(uint256[] memory _values, bool[] memory _true) public onlyOwner returns(bool){
    plans = _values ;
    active = _true ;
    return true;
  }

  function setTiempo(uint256 _dias) public onlyAdmin returns(uint256){

    dias = _dias;
    
    return (_dias);

  }

  function setTiempoUnidades(uint256 _unidades) public onlyOwner returns(uint256){

    unidades = _unidades;
    
    return (_unidades);

  }

  function controlWitdrawl(bool _true_false) public onlyOwner returns(bool){

    onOffWitdrawl = _true_false;
    
    return (_true_false);

  }

  function setRetorno(uint256 _porcentaje) public onlyAdmin returns(uint256){

    porcent = _porcentaje;

    return (porcent);

  }

  function column(address yo, uint256 _largo) public view returns(address[] memory) {

    address[] memory res;
    for (uint256 i = 0; i < _largo; i++) {
      res = actualizarNetwork(res);
      res[i] = padre[yo];
      yo = padre[yo];
    }
    
    return res;
  }

  function depositos(address _user) public view returns(uint256[] memory, uint256[] memory, bool[] memory, bool[] memory, uint256 ){
    Investor storage usuario = investors[_user];

    uint256[] memory amount;
    uint256[] memory time;
    bool[] memory pasive;
    bool[] memory activo;
    uint256 total;
    
     for (uint i = 0; i < usuario.depositos.length; i++) {
       amount = actualizarArrayUint256(amount);
       time = actualizarArrayUint256(time);
       pasive = actualizarArrayBool(pasive);
       activo = actualizarArrayBool(activo);

       Deposito storage dep = usuario.depositos[i];

       time[i] = dep.inicio;
      
      uint finish = dep.inicio + tiempo();
      uint since = usuario.paidAt > dep.inicio ? usuario.paidAt : dep.inicio;
      uint till = block.timestamp > finish ? finish : block.timestamp;

      if (since != 0 && since < till) {
        if (dep.pasivo) {
          total += dep.amount * (till - since) / tiempo() ;
        } 
        activo[i] = true;
      }

      amount[i] = dep.amount;
      pasive[i] = dep.pasivo;      

     }

     return (amount, time, pasive, activo, total);

  }

  function rewardReferers(address yo, uint256 amount, uint256[] memory array, bool _sal) internal {

    address[] memory referi;
    referi = column(yo, array.length);
    uint256 a;
    Investor storage usuario;

    for (uint256 i = 0; i < array.length; i++) {

      if (array[i] != 0) {
        usuario = investors[referi[i]];
        if (usuario.registered && usuario.membership >= block.timestamp && usuario.amount > 0){
          if ( referi[i] != address(0) ) {

            a = amount.mul(array[i]).div(1000);
            if (usuario.amount > a+withdrawable(_msgSender())) {

              usuario.amount -= a;
              if(_sal){
                usuario.balanceSal += a;
              }else{
                usuario.balanceRef += a;
                usuario.totalRef += a;
              }
              
              totalRefRewards += a;
              
            }else{

              if(_sal){
                usuario.balanceSal += usuario.amount;
              }else{
                usuario.balanceRef += usuario.amount;
                usuario.totalRef += usuario.amount;
              }
              
              totalRefRewards += usuario.amount;
              delete usuario.amount;
              
            }
            

          }else{
            break;
          }
        }
        
      } else {
        break;
      }
      
    }
  }

  function discountDeposits(address _user, uint256 _valor) public { // tiene que se internal

    Investor storage usuario = investors[_user];
    
    for (uint i = 0; i < usuario.depositos.length; i++) {

      Deposito storage dep = usuario.depositos[i];
      if(dep.amount >= _valor){
        dep.amount = dep.amount-_valor;
        delete _valor;
      }else{
        _valor = _valor-dep.amount;
        delete dep.amount;
        
      }
         
    }
  }

  function asignarBloke(address _user ,uint256 _plan) public onlyAdmin returns (bool){
    if(_plan >= plans.length )revert();
    if(!active[_plan])revert();

    Investor storage usuario = investors[_user];

    if(!usuario.registered)revert();

    uint256 _value = plans[_plan];

    usuario.depositos.push(Deposito(block.timestamp, (_value.mul(porcent)).div(100), false));
    usuario.amount += (_value.mul(porcent)).div(100);


    return true;
  }

  function registro(address _sponsor, string memory _datos) public{
    
    Investor storage usuario = investors[_msgSender()];

    if(usuario.registered)revert("ya estas registrado");

    if(precioRegistro > 0){

      if( USDT_Contract.allowance(_msgSender(), address(this)) < precioRegistro)revert();
      if( !USDT_Contract.transferFrom(_msgSender(), address(this), precioRegistro))revert();

    }

    if (activerFee >= 2){
       for (uint256 i = 0; i < wallet.length; i++) {
        USDT_Contract.transfer(walletFee[i], precioRegistro.mul(valorFee[i]).div(100));
      }
    }
        usuario.registered = true;
        usuario.membership = block.timestamp + duracionMembership*unidades;
        usuario.data = _datos;
        padre[_msgSender()] = _sponsor;

        if (_sponsor != address(0) ){
          Investor storage sponsor = investors[_sponsor];
          sponsor.directos++;
          
        }
        
        totalInvestors++;

        rangoReclamado[_msgSender()] = [false,false,false,false,false,false,false];
        idToAddress[lastUserId] = _msgSender();
        addressToId[_msgSender()] = lastUserId;
        
        lastUserId++;


  }

  function buyBlocks(uint256 _bloks) public {

    if(_bloks <= 0)revert("cantidad minima de blokes es 1");

    Investor storage usuario = investors[_msgSender()];

    if ( usuario.registered) {

      uint256 _value = PRECIO_BLOCK*_bloks;

      if( USDT_Contract.allowance(_msgSender(), address(this)) < _value)revert("saldo aprovado insuficiente");
      if( !USDT_Contract.transferFrom(_msgSender(), address(this), _value) )revert("tranferencia fallida");
      
      if (padre[_msgSender()] != address(0) ){
        if (usuario.depositos.length < inversiones ){
          
          rewardReferers(_msgSender(), _value, primervez, false);
          
        }else{
          rewardReferers(_msgSender(), _value, porcientos, false);

        }
      }

      usuario.depositos.push(Deposito(block.timestamp,(_value.mul(porcent)).div(100), true));
      usuario.invested += _value;
      usuario.amount += (_value.mul(porcent)).div(100);

      totalInvested += _value;

      for (uint256 i = 0; i < wallet.length; i++) {
        USDT_Contract.transfer(wallet[i], _value.mul(valor[i]).div(100));
      }

      
    } else {
      revert("no esta registrado");
    }
    
  }

   function withdrawableRange(address any_user) public view returns (uint256 amount) {
    Investor memory user = investors[any_user];

    amount = user.blokesDirectos*PRECIO_BLOCK;//canditad de blokesDirectos
  
  
  }

  function newRecompensa() public {

    if (!onOffWitdrawl)revert();

    uint256 amount = withdrawableRange(_msgSender());

    for (uint256 index = 0; index < gananciasRango.length; index++) {

      if(amount >= puntosRango[index] && !rangoReclamado[_msgSender()][index]){

        USDT_Contract.transfer(_msgSender(), gananciasRango[index]);
        rangoReclamado[_msgSender()][index] = true;
      }
      
    }

  }

  function actualizarNetwork(address[] memory oldNetwork)public pure returns ( address[] memory) {
    address[] memory newNetwork =   new address[](oldNetwork.length+1);

    for(uint i = 0; i < oldNetwork.length; i++){
        newNetwork[i] = oldNetwork[i];
    }
    
    return newNetwork;
  }

  function actualizarArrayBool(bool[] memory old)public pure returns ( bool[] memory) {
    bool[] memory newA =   new bool[](old.length+1);

    for(uint i = 0; i < old.length; i++){
        newA[i] = old[i];
    }
    
    return newA;
  }

  function actualizarArrayUint256(uint256[] memory old)public pure returns ( uint256[] memory) {
    uint256[] memory newA =   new uint256[](old.length+1);

    for(uint i = 0; i < old.length; i++){
        newA[i] = old[i];
    }
    
    return newA;
  }

  function allnetwork( address[] memory network ) public view returns ( address[] memory) {

    Investor storage user;

    for (uint i = 0; i < network.length; i++) {

      user = investors[network[i]];
      
      address userLeft = address(0);

      for (uint u = 0; u < network.length; u++) {
        if (userLeft == network[u]){
          userLeft = address(0);
        }
      }

      if( userLeft != address(0) ){
        network = actualizarNetwork(network);
        network[network.length-1] = userLeft;
      }

    }

    return network;
  }


  function withdrawable(address any_user) public view returns (uint256) {

    Investor memory investor2 = investors[any_user];

    uint256 saldo = investor2.amount;

    uint256[] memory amount;
    uint256[] memory time;
    bool[] memory pasive;
    bool[] memory activo;
    uint256 total;

    (amount, time, pasive, activo, total) = depositos(any_user);

    if (saldo >= total) {
      return total;
    }else{
      return saldo;
    }

  }

  function withdrawable2(address any_user) public view returns (uint256) {

    Investor memory investor2 = investors[any_user];

    uint256 saldo = investor2.balanceRef+investor2.balanceSal;
    
    return saldo;

  }

  function withdraw() public {

    if (!onOffWitdrawl)revert();

    uint256 _value = withdrawable(_msgSender());

    if( USDT_Contract.balanceOf(address(this)) < _value )revert();
    if( _value < MIN_RETIRO )revert();

    if ( activerFee >= 1 ) {
      for (uint256 i = 0; i < walletFee.length; i++) {
        USDT_Contract.transfer(walletFee[i], _value.mul(valorFee[i]).div(100));
      }
    
      USDT_Contract.transfer(_msgSender(), _value.mul(descuento).div(100));
      
    }else{
      USDT_Contract.transfer(_msgSender(), _value.mul(descuento).div(100));
      
    }

    rewardReferers(_msgSender(), _value, porcientosSalida, true);

    Investor storage usuario = investors[_msgSender()];

    usuario.amount -= _value;
    usuario.withdrawn += _value;
    usuario.paidAt = block.timestamp;

    totalRefWitdrawl += _value;

  }

  function withdraw2() public {

    if (!onOffWitdrawl)revert();

    uint256 _value = withdrawable2(_msgSender());

    if( USDT_Contract.balanceOf(address(this)) < _value )revert();
    if( _value < MIN_RETIRO )revert();

    if ( activerFee >= 1 ) {
      for (uint256 i = 0; i < walletFee.length; i++) {
        USDT_Contract.transfer(walletFee[i], _value.mul(valorFee[i]).div(100));
      }
    
      USDT_Contract.transfer(_msgSender(), _value.mul(descuento).div(100));
      
    }else{
      USDT_Contract.transfer(_msgSender(), _value.mul(descuento).div(100));
      
    }

    rewardReferers(_msgSender(), _value, porcientosSalida, true);

    Investor storage usuario = investors[_msgSender()];

    usuario.amount -= _value;
    usuario.withdrawn += _value;
    delete usuario.balanceRef;
    delete usuario.balanceSal;

    totalRefWitdrawl += _value;

  }

  function redimTokenPrincipal02(uint256 _value) public onlyOwner returns (uint256) {

    if ( USDT_Contract.balanceOf(address(this)) < _value)revert();

    USDT_Contract.transfer(owner, _value);

    return _value;

  }

  function redimTRX() public onlyOwner returns (uint256){

    owner.transfer(address(this).balance);

    return address(this).balance;

  }

  fallback() external payable {}

  receive() external payable {}

}