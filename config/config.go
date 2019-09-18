package config

import "time"

type DbStdConfig struct {
	Driver   string
	Username string
	Password string
	Protocol string
	Address  string
	Port     string
	Dbname   string
	Params   string
}

//DbConfig ..
type DbConfig struct {
	DbStdConfig
	MaxIdleConns int
	MaxOpenConns int
	KeepAlive    time.Duration
	//缓存配置
	Cache        CacheConfig
	CacheType    string
	CacheMaxSize int
	CacheTimeout time.Duration
	Redis        RedisConfig
	//从库
	Slaves []DbStdConfig
}

//CacheConfig ..
type CacheConfig struct {
	Type    string
	Servers []string
	Config  struct {
		Prefix     string
		Expiration int32
	}
}

type RedisConfig struct {
	IsCluster  bool
	Server     string
	Prefix     string
	Expiration int32
	PoolSize   int
	//以下两个在集群下无效
	Db       int
	Password string
}
